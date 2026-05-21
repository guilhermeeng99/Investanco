import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/helpers.dart';

void main() {
  late AppDatabase db;
  late AssetRepositoryImpl repository;

  setUp(() {
    db = memoryDatabase();
    repository = AssetRepositoryImpl(db);
  });

  test('save then watchAll emits the asset', () async {
    final result = await repository.save(assetFactory());

    expect(result, const Right<Failure, Unit>(unit));
    expect(await repository.watchAll().first, [assetFactory()]);
  });

  test('metadata round-trips through JSON storage', () async {
    final asset = assetFactory(
      kind: AssetKind.fixedIncome,
      metadata: const {'fiBasis': 'cdi', 'fiRate': '110'},
    );

    await repository.save(asset);

    final stored = (await repository.watchAll().first).single;
    expect(stored.metadata, {'fiBasis': 'cdi', 'fiRate': '110'});
  });

  test('delete returns InUseFailure when a transaction references it', () async {
    await repository.save(assetFactory());
    await TransactionRepositoryImpl(db).save(transactionFactory());

    final result = await repository.delete('a1');

    expect(result, const Left<Failure, Unit>(InUseFailure()));
  });
}
