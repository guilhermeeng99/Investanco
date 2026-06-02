import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/institution_factory.dart';
import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/helpers.dart';
import '../../../harness/mocks.dart';

void main() {
  late AppDatabase db;
  late InstitutionRepositoryImpl repository;

  setUp(() {
    db = memoryDatabase();
    repository = InstitutionRepositoryImpl(db);
  });

  test('save then watchAll emits the institution', () async {
    final result = await repository.save(institutionFactory());

    expect(result, const Right<Failure, Unit>(unit));
    expect(await repository.watchAll().first, [institutionFactory()]);
  });

  test('save upserts when id matches', () async {
    await repository.save(institutionFactory());
    await repository.save(institutionFactory(name: 'Nubank PJ'));

    final list = await repository.watchAll().first;
    expect(list.length, 1);
    expect(list.single.name, 'Nubank PJ');
  });

  test('delete removes an unreferenced institution', () async {
    await repository.save(institutionFactory());

    final result = await repository.delete('i1');

    expect(result, const Right<Failure, Unit>(unit));
    expect(await repository.watchAll().first, isEmpty);
  });

  test('delete returns InUseFailure when a transaction references it', () async {
    await repository.save(institutionFactory());
    await db.into(db.assets).insert(
          AssetRow(
            id: 'a1',
            ticker: 'PETR4',
            name: 'Petrobras PN',
            kind: 'stockBr',
            market: 'br',
            currency: 'brl',
            institutionId: 'i1',
            metadata: '{}',
            createdAt: DateTime(2026),
          ),
        );
    await TransactionRepositoryImpl(db).save(transactionFactory());

    final result = await repository.delete('i1');

    expect(result, const Left<Failure, Unit>(InUseFailure()));
  });

  test('delete returns InUseFailure when an asset references it', () async {
    await repository.save(institutionFactory());
    await db.into(db.assets).insert(
          AssetRow(
            id: 'a1',
            ticker: 'PETR4',
            name: 'Petrobras PN',
            kind: 'stockBr',
            market: 'br',
            currency: 'brl',
            institutionId: 'i1',
            metadata: '{}',
            createdAt: DateTime(2026),
          ),
        );

    final result = await repository.delete('i1');

    expect(result, const Left<Failure, Unit>(InUseFailure()));
  });

  test('rejects a duplicate name (case-insensitive) from another institution',
      () async {
    await repository.save(institutionFactory(id: 'i1', name: 'Nubank'));

    final result =
        await repository.save(institutionFactory(id: 'i2', name: 'nubank'));

    final failure =
        result.swap().getOrElse(() => throw StateError('x')) as ValidationFailure;
    expect(failure.code, ValidationCode.duplicateInstitutionName);
    expect(await repository.watchAll().first, hasLength(1));
  });

  test('allows re-saving an institution under its own name (same id)', () async {
    await repository.save(institutionFactory(id: 'i1', name: 'Nubank'));

    final result =
        await repository.save(institutionFactory(id: 'i1', name: 'Nubank'));

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('mirrors writes to the cloud on save and delete', () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any())).thenAnswer((_) async {});
    when(() => mirror.delete(any(), any())).thenAnswer((_) async {});
    final repo = InstitutionRepositoryImpl(db, mirror);

    await repo.save(institutionFactory(id: 'i1'));
    verify(() => mirror.upsert('institutions', 'i1', any())).called(1);

    await repo.delete('i1');
    verify(() => mirror.delete('institutions', 'i1')).called(1);
  });

  test('save surfaces the failure and skips the cache when the remote fails',
      () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any()))
        .thenThrow(Exception('offline'));
    final repo = InstitutionRepositoryImpl(db, mirror);

    final result = await repo.save(institutionFactory(id: 'i1'));

    expect(result.isLeft(), isTrue);
    // Write-through: nothing is cached locally when the cloud write fails.
    expect(await db.select(db.institutions).get(), isEmpty);
  });
}
