import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
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

  test('save surfaces the failure and skips the cache when the remote fails',
      () async {
    final mirror = MockRemoteMirror();
    when(() => mirror.upsert(any(), any(), any()))
        .thenThrow(Exception('offline'));
    final repo = TransactionRepositoryImpl(db, mirror);

    final result = await repo.save(transactionFactory(id: 't1'));

    expect(result.isLeft(), isTrue);
    // Write-through: nothing is cached locally when the cloud write fails.
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('rejects a future-dated transaction and skips the cache', () async {
    final result = await repository.save(
      transactionFactory(date: DateTime(3000)),
    );

    final failure =
        result.swap().getOrElse(() => throw StateError('x')) as ValidationFailure;
    expect(failure.code, ValidationCode.futureTransactionDate);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('rejects a buy with a non-positive quantity and skips the cache',
      () async {
    final result = await repository.save(
      transactionFactory(quantity: 0),
    );

    final failure =
        result.swap().getOrElse(() => throw StateError('x')) as ValidationFailure;
    expect(failure.code, ValidationCode.nonPositiveQuantity);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('rejects a sell with nothing held (oversell) and skips the cache',
      () async {
    final result = await repository.save(
      transactionFactory(kind: TransactionKind.sell),
    );

    final failure =
        result.swap().getOrElse(() => throw StateError('x')) as ValidationFailure;
    expect(failure.code, ValidationCode.oversell);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('allows a sell covered by an earlier buy in the same position', () async {
    await repository.save(
      transactionFactory(id: 'b', quantity: 10, date: DateTime(2026, 1, 1)),
    );

    final result = await repository.save(
      transactionFactory(
        id: 's',
        kind: TransactionKind.sell,
        quantity: 4,
        date: DateTime(2026, 2, 1),
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('allows a fixed-income redemption (qty-1 deposit then redemption)',
      () async {
    await repository.save(
      transactionFactory(id: 'dep', date: DateTime(2026, 1, 1)),
    );

    final result = await repository.save(
      transactionFactory(
        id: 'red',
        kind: TransactionKind.sell,
        date: DateTime(2026, 2, 1),
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('a sell in a different institution from the buy oversells', () async {
    await repository.save(
      transactionFactory(id: 'b', institutionId: 'i1', quantity: 10),
    );

    final result = await repository.save(
      transactionFactory(
        id: 's',
        institutionId: 'i2',
        kind: TransactionKind.sell,
        date: DateTime(2026, 3, 1),
      ),
    );

    final failure =
        result.swap().getOrElse(() => throw StateError('x')) as ValidationFailure;
    expect(failure.code, ValidationCode.oversell);
  });
}
