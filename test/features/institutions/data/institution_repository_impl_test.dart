import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';

import '../../../harness/factories/institution_factory.dart';

void main() {
  late AppDatabase db;
  late InstitutionRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = InstitutionRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
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

    final result = await repository.delete('i1');

    expect(result, const Left<Failure, Unit>(InUseFailure()));
  });
}
