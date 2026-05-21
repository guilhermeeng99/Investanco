import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/helpers.dart';
import '../../../harness/mocks.dart';

void main() {
  late AppDatabase db;
  late TransactionRepositoryImpl repository;

  setUp(() {
    db = memoryDatabase();
    repository = TransactionRepositoryImpl(db);
  });

  test('save then watchAll emits the transaction', () async {
    final tx = transactionFactory();

    expect(await repository.save(tx), const Right<Failure, Unit>(unit));
    expect(await repository.watchAll().first, [tx]);
  });

  test('watchAll returns newest first', () async {
    await repository.save(transactionFactory(id: 't1', date: DateTime(2026, 1, 1)));
    await repository.save(transactionFactory(id: 't2', date: DateTime(2026, 1, 2)));

    final list = await repository.watchAll().first;
    expect(list.map((t) => t.id), ['t2', 't1']);
  });

  test('watchByAsset filters and returns oldest first', () async {
    await repository.save(
      transactionFactory(id: 't1', date: DateTime(2026, 1, 2)),
    );
    await repository.save(
      transactionFactory(id: 't2', date: DateTime(2026, 1, 1)),
    );
    await repository.save(transactionFactory(id: 't3', assetId: 'a2'));

    final list = await repository.watchByAsset('a1').first;
    expect(list.map((t) => t.id), ['t2', 't1']);
  });

  test('delete removes the transaction', () async {
    await repository.save(transactionFactory());

    expect(await repository.delete('t1'), const Right<Failure, Unit>(unit));
    expect(await repository.watchAll().first, isEmpty);
  });

  test('mirrors writes to the cloud on save and delete', () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any())).thenAnswer((_) async {});
    when(() => mirror.delete(any(), any())).thenAnswer((_) async {});
    final repo = TransactionRepositoryImpl(db, mirror);

    await repo.save(transactionFactory(id: 't1'));
    verify(() => mirror.upsert('transactions', 't1', any())).called(1);

    await repo.delete('t1');
    verify(() => mirror.delete('transactions', 't1')).called(1);
  });
}
