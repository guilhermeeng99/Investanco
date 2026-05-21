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

  Future<void> seedAll() async {
    await db.into(db.institutions).insert(
          InstitutionRow(
            id: 'i1',
            name: 'Nubank',
            kind: 'bank',
            currency: 'brl',
            createdAt: DateTime(2026),
          ),
        );
    await db.into(db.assets).insert(
          AssetRow(
            id: 'a1',
            ticker: 'PETR4',
            name: 'Petrobras',
            kind: 'stockBr',
            market: 'br',
            currency: 'brl',
            metadata: '{}',
            createdAt: DateTime(2026),
          ),
        );
    await db.into(db.transactions).insert(
          TransactionRow(
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
          ),
        );
    await db.into(db.snapshots).insert(
          SnapshotRow(
            id: '2026-05-20',
            date: DateTime(2026, 5, 20),
            totalValueMinor: 100000,
            totalInvestedMinor: 90000,
            totalPlMinor: 10000,
            currency: 'brl',
          ),
        );
  }

  test('push uploads local rows under users/{uid}', () async {
    await seedAll();

    final result = await service.sync('u1');

    expect(result.isRight(), isTrue);
    final institutions =
        await firestore.collection('users/u1/institutions').get();
    expect(institutions.docs.single.id, 'i1');
    final transactions =
        await firestore.collection('users/u1/transactions').get();
    expect(transactions.docs.single.id, 't1');
  });

  test('pull restores every mirrored table into an empty local db', () async {
    await seedAll();
    await service.sync('u1'); // push everything up

    await db.delete(db.institutions).go();
    await db.delete(db.assets).go();
    await db.delete(db.transactions).go();
    await db.delete(db.snapshots).go();

    await service.sync('u1'); // pull restores

    expect((await db.select(db.institutions).get()).single.id, 'i1');
    expect((await db.select(db.assets).get()).single.ticker, 'PETR4');
    expect((await db.select(db.transactions).get()).single.quantity, 10);
    expect((await db.select(db.snapshots).get()).single.id, '2026-05-20');
  });

  test("does not pull another user's data", () async {
    await seedAll();
    await service.sync('u1');

    await db.delete(db.institutions).go();
    await service.sync('u2'); // different user → nothing to pull

    expect(await db.select(db.institutions).get(), isEmpty);
  });

  test('clear wipes both Firestore and local data', () async {
    await seedAll();
    await service.sync('u1'); // mirror up

    final result = await service.clear('u1');

    expect(result.isRight(), isTrue);
    expect(
      (await firestore.collection('users/u1/institutions').get()).docs,
      isEmpty,
    );
    expect(
      (await firestore.collection('users/u1/transactions').get()).docs,
      isEmpty,
    );
    expect(await db.select(db.institutions).get(), isEmpty);
    expect(await db.select(db.assets).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.snapshots).get(), isEmpty);
  });
}
