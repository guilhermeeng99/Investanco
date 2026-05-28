import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/helpers.dart';
import '../../../harness/mocks.dart';

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

  test('rejects a duplicate (ticker, market) from another asset', () async {
    await repository.save(assetFactory(id: 'a1', ticker: 'PETR4'));

    final result = await repository.save(assetFactory(id: 'a2', ticker: 'petr4'));

    final failure =
        result.swap().getOrElse(() => throw StateError('x')) as ValidationFailure;
    expect(failure.code, ValidationCode.duplicateAsset);
    expect(await repository.watchAll().first, hasLength(1));
  });

  test('allows the same ticker in a different market', () async {
    await repository.save(
      assetFactory(id: 'a1', ticker: 'AAPL', market: Market.us),
    );

    final result = await repository.save(
      assetFactory(id: 'a2', ticker: 'AAPL', market: Market.global),
    );

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('tolerates a blank or corrupt metadata cell (defaults to empty)',
      () async {
    // A bad metadata cell must not throw inside the reactive watchAll stream
    // and break the whole assets list.
    await db.into(db.assets).insert(
          AssetRow(
            id: 'bad',
            ticker: 'BAD',
            name: 'Corrupt',
            kind: 'crypto',
            market: 'global',
            currency: 'brl',
            metadata: 'not-json{',
            createdAt: DateTime(2026),
          ),
        );

    final assets = await repository.watchAll().first;

    expect(assets.single.metadata, isEmpty);
  });

  test('mirrors writes to the cloud on save and delete', () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any())).thenAnswer((_) async {});
    when(() => mirror.delete(any(), any())).thenAnswer((_) async {});
    final repo = AssetRepositoryImpl(db, mirror);

    await repo.save(assetFactory(id: 'a1'));
    verify(() => mirror.upsert('assets', 'a1', any())).called(1);

    await repo.delete('a1');
    verify(() => mirror.delete('assets', 'a1')).called(1);
  });

  test('save surfaces the failure and skips the cache when the remote fails',
      () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any()))
        .thenThrow(Exception('offline'));
    final repo = AssetRepositoryImpl(db, mirror);

    final result = await repo.save(assetFactory(id: 'a1'));

    expect(result.isLeft(), isTrue);
    expect(await db.select(db.assets).get(), isEmpty);
  });
}
