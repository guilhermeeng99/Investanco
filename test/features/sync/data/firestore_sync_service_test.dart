import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/features/sync/data/firestore_sync_service.dart';

import '../../../harness/helpers.dart';

void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late FirestoreSyncService service;

  setUp(() {
    db = memoryDatabase();
    firestore = FakeFirebaseFirestore();
    service = FirestoreSyncService(db, firestore);
  });

  final institution = InstitutionRow(
    id: 'i1',
    name: 'Nubank',
    kind: 'bank',
    currency: 'brl',
    createdAt: DateTime(2026),
  );
  final asset = AssetRow(
    id: 'a1',
    ticker: 'PETR4',
    name: 'Petrobras',
    kind: 'stockBr',
    market: 'br',
    currency: 'brl',
    metadata: '{}',
    createdAt: DateTime(2026),
  );
  final transaction = TransactionRow(
    id: 't1',
    institutionId: 'i1',
    assetId: 'a1',
    kind: 'buy',
    quantity: 10,
    unitPriceMinor: 3850,
    feesMinor: 0,
    amountMinor: 38500,
    currency: 'brl',
    date: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final snapshot = SnapshotRow(
    id: '2026-05-20',
    date: DateTime(2026, 5, 20),
    totalValueMinor: 100000,
    totalInvestedMinor: 90000,
    totalPlMinor: 10000,
    currency: 'brl',
  );
  final assetClass = AssetClassRow(
    id: 'c1',
    name: 'US Stocks',
    iconKey: 'chart',
    colorValue: 0xFF6366F1,
    targetPercent: 40,
    createdAt: DateTime(2026),
  );

  Future<void> putDoc(
    String userId,
    String name,
    String id,
    Map<String, dynamic> json,
  ) =>
      firestore.collection('users/$userId/$name').doc(id).set(json);

  Future<void> seedCloud(String userId) async {
    await putDoc(userId, 'institutions', institution.id, institution.toJson());
    await putDoc(userId, 'assets', asset.id, asset.toJson());
    await putDoc(userId, 'transactions', transaction.id, transaction.toJson());
    await putDoc(userId, 'snapshots', snapshot.id, snapshot.toJson());
    await putDoc(userId, 'asset_classes', assetClass.id, assetClass.toJson());
  }

  test('sync pulls every mirrored collection into the local cache', () async {
    await seedCloud('u1');

    final result = await service.sync('u1');

    expect(result.isRight(), isTrue);
    expect((await db.select(db.institutions).get()).single.id, 'i1');
    expect((await db.select(db.assets).get()).single.ticker, 'PETR4');
    expect((await db.select(db.transactions).get()).single.quantity, 10);
    expect((await db.select(db.snapshots).get()).single.id, '2026-05-20');
    expect((await db.select(db.assetClasses).get()).single.id, 'c1');
  });

  test('sync removes a local asset class deleted on another device', () async {
    // Authoritative pull also propagates asset_classes deletes (the cloud has
    // none, so the stale local row must go).
    await db.into(db.assetClasses).insert(assetClass);
    await putDoc('u1', 'institutions', institution.id, institution.toJson());

    await service.sync('u1');

    expect(await db.select(db.assetClasses).get(), isEmpty);
  });

  test('sync removes a local row that was deleted on another device', () async {
    // Stale local rows; the cloud only has the institution (t1 deleted elsewhere).
    await db.into(db.institutions).insert(institution);
    await db.into(db.transactions).insert(transaction);
    await putDoc('u1', 'institutions', institution.id, institution.toJson());

    await service.sync('u1');

    expect((await db.select(db.institutions).get()).single.id, 'i1');
    expect(await db.select(db.transactions).get(), isEmpty); // delete propagated
  });

  test('sync overwrites a locally-edited row with the cloud version', () async {
    await db.into(db.institutions).insert(institution); // local: "Nubank"
    await putDoc(
      'u1',
      'institutions',
      institution.id,
      institution.copyWith(name: 'Nubank PJ').toJson(),
    );

    await service.sync('u1');

    expect((await db.select(db.institutions).get()).single.name, 'Nubank PJ');
  });

  test('sync preserves quotes and settings (not mirrored)', () async {
    await db.into(db.settings).insert(
          const SettingsRow(id: 0, themeMode: 'dark', baseCurrency: 'brl'),
        );
    await db.into(db.quotes).insert(
          QuoteRow(
            assetId: 'a1',
            unitPriceMinor: 4000,
            currency: 'brl',
            asOf: DateTime(2026),
            fetchedAt: DateTime(2026),
            source: 'brapi',
          ),
        );
    await seedCloud('u1');

    await service.sync('u1');

    expect(await db.select(db.settings).get(), isNotEmpty);
    expect(await db.select(db.quotes).get(), isNotEmpty);
  });

  test("does not pull another user's data", () async {
    await seedCloud('u1');

    await service.sync('u2'); // different user → empty cloud → empty local

    expect(await db.select(db.institutions).get(), isEmpty);
  });

  test('resetLocal wipes local rows but leaves Firestore intact', () async {
    await db.into(db.institutions).insert(institution);
    await seedCloud('u1');

    await service.resetLocal();

    expect(await db.select(db.institutions).get(), isEmpty);
    expect(
      (await firestore.collection('users/u1/institutions').get()).docs,
      isNotEmpty,
    );
  });

  test('clear wipes both Firestore and local data', () async {
    await db.into(db.institutions).insert(institution);
    await db.into(db.transactions).insert(transaction);
    await db.into(db.assetClasses).insert(assetClass);
    await seedCloud('u1');

    final result = await service.clear('u1');

    expect(result.isRight(), isTrue);
    for (final name in const [
      'institutions',
      'assets',
      'transactions',
      'snapshots',
      'asset_classes',
    ]) {
      expect(
        (await firestore.collection('users/u1/$name').get()).docs,
        isEmpty,
        reason: 'cloud $name should be wiped',
      );
    }
    expect(await db.select(db.institutions).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.assetClasses).get(), isEmpty);
  });
}
