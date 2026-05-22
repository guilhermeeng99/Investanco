import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_factory.dart';
import '../../../harness/factories/institution_factory.dart';
import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockTransactionRepository transactions;
  late MockAssetRepository assets;
  late MockInstitutionRepository institutions;

  final tx = transactionFactory();
  final asset = assetFactory();
  final institution = institutionFactory();

  setUp(() {
    transactions = MockTransactionRepository();
    assets = MockAssetRepository();
    institutions = MockInstitutionRepository();
    when(transactions.watchAll).thenAnswer((_) => Stream.value([tx]));
    when(assets.watchAll).thenAnswer((_) => Stream.value([asset]));
    when(institutions.watchAll).thenAnswer((_) => Stream.value([institution]));
  });

  TransactionsCubit build() => TransactionsCubit(
        transactions,
        assets,
        institutions,
        const FakeIdGenerator(),
      );

  blocTest<TransactionsCubit, TransactionsState>(
    'emits Loaded only once all three streams have produced data',
    build: build,
    expect: () => [
      TransactionsLoaded(
        transactions: [tx],
        assets: [asset],
        institutions: [institution],
      ),
    ],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'emits Error when a backing stream fails',
    build: () {
      when(transactions.watchAll)
          .thenAnswer((_) => Stream.error(Exception('boom')));
      return build();
    },
    expect: () => [const TransactionsError()],
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'add() builds a transaction with a generated id and persists it',
    build: build,
    setUp: () => when(() => transactions.save(any()))
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.add(
      institutionId: 'i1',
      assetId: 'a1',
      kind: TransactionKind.buy,
      quantity: 3,
      unitPrice: Money.fromMajor(10, Currency.brl),
      fees: const Money.zero(Currency.brl),
      amount: Money.fromMajor(30, Currency.brl),
      date: DateTime(2026, 5, 1),
    ),
    verify: (_) {
      final captured =
          verify(() => transactions.save(captureAny())).captured.single;
      expect((captured as AssetTransaction).id, 'generated-id');
      expect(captured.assetId, 'a1');
      expect(captured.quantity, 3);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'edit() persists the existing transaction (same id)',
    build: build,
    setUp: () => when(() => transactions.save(any()))
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.edit(tx),
    verify: (_) {
      final captured =
          verify(() => transactions.save(captureAny())).captured.single;
      expect((captured as AssetTransaction).id, tx.id);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'remove() surfaces a failure from the repository',
    build: build,
    setUp: () => when(() => transactions.delete(any()))
        .thenAnswer((_) async => const Left(CacheFailure())),
    act: (cubit) async {
      final failure = await cubit.remove('t1');
      expect(failure, isA<CacheFailure>());
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'setInstitutionFilter narrows visibleTransactions to that institution',
    build: () {
      when(transactions.watchAll).thenAnswer(
        (_) => Stream.value([
          transactionFactory(id: 't1', institutionId: 'i1'),
          transactionFactory(id: 't2', institutionId: 'i2'),
        ]),
      );
      when(institutions.watchAll).thenAnswer(
        (_) => Stream.value([
          institutionFactory(id: 'i1'),
          institutionFactory(id: 'i2', name: 'Avenue'),
        ]),
      );
      return build();
    },
    act: (cubit) => cubit.setInstitutionFilter('i2'),
    skip: 1,
    verify: (cubit) {
      final state = cubit.state as TransactionsLoaded;
      expect(state.institutionFilter, 'i2');
      expect(state.visibleTransactions.map((t) => t.id), ['t2']);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'setInstitutionFilter(null) clears the filter and shows all',
    build: () {
      when(transactions.watchAll).thenAnswer(
        (_) => Stream.value([
          transactionFactory(id: 't1', institutionId: 'i1'),
          transactionFactory(id: 't2', institutionId: 'i2'),
        ]),
      );
      when(institutions.watchAll).thenAnswer(
        (_) => Stream.value([
          institutionFactory(id: 'i1'),
          institutionFactory(id: 'i2', name: 'Avenue'),
        ]),
      );
      return build();
    },
    act: (cubit) {
      cubit
        ..setInstitutionFilter('i1')
        ..setInstitutionFilter(null);
    },
    verify: (cubit) {
      final state = cubit.state as TransactionsLoaded;
      expect(state.institutionFilter, isNull);
      expect(state.visibleTransactions.map((t) => t.id), ['t1', 't2']);
    },
  );

  blocTest<TransactionsCubit, TransactionsState>(
    'filter resets to all when the filtered institution is deleted',
    build: () {
      final instCtrl = StreamController<List<Institution>>();
      addTearDown(instCtrl.close);
      when(transactions.watchAll).thenAnswer((_) => Stream.value([tx]));
      when(institutions.watchAll).thenAnswer((_) => instCtrl.stream);
      _institutionController = instCtrl;
      return build();
    },
    act: (cubit) async {
      _institutionController.add([institutionFactory(id: 'i1')]);
      await Future<void>.delayed(Duration.zero);
      cubit.setInstitutionFilter('i1');
      _institutionController.add(<Institution>[]);
      await Future<void>.delayed(Duration.zero);
    },
    verify: (cubit) {
      final state = cubit.state as TransactionsLoaded;
      expect(state.institutionFilter, isNull);
      expect(state.institutions, isEmpty);
    },
  );
}

/// Bridges the deletion test's [StreamController] from `build` into `act`.
late StreamController<List<Institution>> _institutionController;
