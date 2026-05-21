import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
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
}
