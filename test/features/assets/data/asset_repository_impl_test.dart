import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

import '../../../harness/factories/asset_factory.dart';

void main() {
  late AppDatabase db;
  late AssetRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = AssetRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('save then watchAll emits the asset', () async {
    final result = await repository.save(assetFactory());

    expect(result, const Right<Failure, Unit>(unit));
    expect(await repository.watchAll().first, [assetFactory()]);
  });

  test('metadata round-trips through JSON storage', () async {
    final asset = assetFactory(
      kind: AssetKind.fixedIncome,
      metadata: const {'index': 'cdi', 'rate': '1.10'},
    );

    await repository.save(asset);

    final stored = (await repository.watchAll().first).single;
    expect(stored.metadata, {'index': 'cdi', 'rate': '1.10'});
  });

  test('delete returns InUseFailure when a transaction references it', () async {
    await repository.save(assetFactory());
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: 't1',
            institutionId: 'i1',
            assetId: 'a1',
            kind: 'buy',
            quantity: 1,
            unitPriceMinor: 100,
            feesMinor: 0,
            amountMinor: 100,
            currency: 'brl',
            date: DateTime(2026, 1, 2),
            createdAt: DateTime(2026, 1, 2),
            updatedAt: DateTime(2026, 1, 2),
          ),
        );

    final result = await repository.delete('a1');

    expect(result, const Left<Failure, Unit>(InUseFailure()));
  });
}
