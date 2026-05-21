import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';

import '../../../harness/factories/institution_factory.dart';
import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/helpers.dart';

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
    await TransactionRepositoryImpl(db).save(transactionFactory());

    final result = await repository.delete('i1');

    expect(result, const Left<Failure, Unit>(InUseFailure()));
  });
}
