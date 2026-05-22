import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/allocation/data/repositories/asset_class_repository_impl.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/usecases/save_asset_class_usecase.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_cubit.dart';
import 'package:investanco/features/allocation/presentation/cubit/allocation_state.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/quotes/data/market_cache_store_impl.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/asset_class_factory.dart';
import '../../../harness/factories/asset_factory.dart';
import '../../../harness/factories/institution_factory.dart';
import '../../../harness/factories/transaction_factory.dart';
import '../../../harness/helpers.dart';
import '../../../harness/mocks.dart';

// Integration-style: the cubit runs against real local repositories over an
// in-memory Drift db (so class CRUD really persists and the streams re-emit),
// while the network sources (quotes, FX, indices) are mocked at their boundary.
void main() {
  late AppDatabase db;
  late MockQuoteRepository quoteRepository;
  late MockFxDataSource fxDataSource;
  late MockIndexDataSource indexDataSource;

  setUp(() {
    db = memoryDatabase();
    quoteRepository = MockQuoteRepository();
    fxDataSource = MockFxDataSource();
    indexDataSource = MockIndexDataSource();
  });

  void stubNetworkEmpty() {
    when(() => quoteRepository.getCached(any()))
        .thenAnswer((_) async => const Right(<Quote>[]));
    when(() => quoteRepository.refresh(any()))
        .thenAnswer((_) async => const Right(<Quote>[]));
    when(() => quoteRepository.lastFetchedAt(any()))
        .thenAnswer((_) async => null);
    when(() => fxDataSource.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right<Failure, double>(1));
    when(() => indexDataSource.series(any(), any()))
        .thenAnswer((_) async => const Right(<IndexPoint>[]));
  }

  AllocationCubit buildCubit() => AllocationCubit(
        TransactionRepositoryImpl(db),
        AssetRepositoryImpl(db),
        AssetClassRepositoryImpl(db),
        SaveAssetClassUseCase(AssetClassRepositoryImpl(db)),
        const HoldingCalculator(),
        quoteRepository,
        fxDataSource,
        const ValuationService(),
        indexDataSource,
        DriftMarketCacheStore(db),
        const FakeIdGenerator('new-class'),
      );

  // A single BR position (10 PETR4 @ R$10 at Nubank) → a held holding.
  Future<void> seedBrPosition() async {
    await InstitutionRepositoryImpl(db).save(institutionFactory(id: 'i1'));
    await AssetRepositoryImpl(db).save(
      assetFactory(id: 'a1', ticker: 'PETR4', kind: AssetKind.stockBr),
    );
    await TransactionRepositoryImpl(db).save(
      transactionFactory(
        id: 't1',
        institutionId: 'i1',
        assetId: 'a1',
        quantity: 10,
        unitPrice: Money.fromMajor(10, Currency.brl),
        fees: const Money.zero(Currency.brl),
        amount: Money.fromMajor(100, Currency.brl),
      ),
    );
  }

  test('emits AllocationLoaded carrying the saved classes', () async {
    await AssetClassRepositoryImpl(db).save(
      assetClassFactory(id: 'eq', name: 'Equities', targetPercent: 60),
    );
    stubNetworkEmpty();
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AllocationState>(
          (s) => s is AllocationLoaded && s.classes.any((c) => c.id == 'eq'),
        ),
      ),
    );
  });

  test('createClass persists a new class with the generated id', () async {
    stubNetworkEmpty();
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s is AllocationLoaded);

    final result = await cubit.createClass(
      name: 'Fixed income',
      targetPercent: 40,
      iconKey: 'chartPie',
      colorValue: 0xFF0000FF,
    );

    expect(result, const Right<Failure, Unit>(unit));
    final stored = await AssetClassRepositoryImpl(db).watchAll().first;
    expect(stored.map((c) => c.id), contains('new-class'));
  });

  test('createClass rejects an out-of-range target without persisting',
      () async {
    stubNetworkEmpty();
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s is AllocationLoaded);

    final result = await cubit.createClass(
      name: 'Too big',
      targetPercent: 150,
      iconKey: 'chartPie',
      colorValue: 1,
    );

    expect(result.isLeft(), isTrue);
    expect(await AssetClassRepositoryImpl(db).watchAll().first, isEmpty);
  });

  test('deleteClass removes the class from the stream', () async {
    await AssetClassRepositoryImpl(db).save(assetClassFactory(id: 'eq'));
    stubNetworkEmpty();
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.stream.firstWhere(
      (s) => s is AllocationLoaded && s.classes.any((c) => c.id == 'eq'),
    );

    await cubit.deleteClass('eq');

    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<AllocationState>(
          (s) => s is AllocationLoaded && s.classes.every((c) => c.id != 'eq'),
        ),
      ),
    );
  });

  test('auto-refreshes exactly once when a held position exists', () async {
    await seedBrPosition();
    stubNetworkEmpty();
    final refreshed = Completer<void>();
    when(() => quoteRepository.refresh(any())).thenAnswer((_) async {
      if (!refreshed.isCompleted) refreshed.complete();
      return const Right(<Quote>[]);
    });

    final cubit = buildCubit();
    addTearDown(cubit.close);

    await refreshed.future;
    verify(() => quoteRepository.refresh(any())).called(1);
  });

  test('skips the network refresh when cached quotes are fresh', () async {
    await seedBrPosition();
    stubNetworkEmpty();
    when(() => quoteRepository.lastFetchedAt(any()))
        .thenAnswer((_) async => DateTime.now());

    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s is AllocationLoaded);
    await pumpEventQueue(); // let the auto-refresh attempt run

    verifyNever(() => quoteRepository.refresh(any()));
  });

  test('clears isRefreshing even when a source throws (no infinite spinner)',
      () async {
    await seedBrPosition();
    stubNetworkEmpty();
    when(() => quoteRepository.lastFetchedAt(any()))
        .thenAnswer((_) async => null);
    when(() => quoteRepository.refresh(any())).thenThrow(Exception('boom'));

    final cubit = buildCubit();
    addTearDown(cubit.close);

    await expectLater(
      cubit.stream,
      emitsInOrder([
        emitsThrough(
          predicate<AllocationState>(
            (s) => s is AllocationLoaded && s.isRefreshing,
          ),
        ),
        emitsThrough(
          predicate<AllocationState>(
            (s) => s is AllocationLoaded && !s.isRefreshing,
          ),
        ),
      ]),
    );
  });

  test('emits AllocationError when a backing stream fails', () async {
    final txRepo = MockTransactionRepository();
    final assetRepo = MockAssetRepository();
    final classRepo = MockAssetClassRepository();
    when(txRepo.watchAll).thenAnswer((_) => Stream.error(Exception('boom')));
    when(assetRepo.watchAll)
        .thenAnswer((_) => const Stream<List<Asset>>.empty());
    when(classRepo.watchAll)
        .thenAnswer((_) => const Stream<List<AssetClass>>.empty());
    stubNetworkEmpty();
    final marketCache = MockMarketCacheStore();
    when(() => marketCache.lastFxRate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => null);
    when(marketCache.allIndexSeries)
        .thenAnswer((_) async => <EconomicIndex, List<IndexPoint>>{});

    final cubit = AllocationCubit(
      txRepo,
      assetRepo,
      classRepo,
      SaveAssetClassUseCase(classRepo),
      const HoldingCalculator(),
      quoteRepository,
      fxDataSource,
      const ValuationService(),
      indexDataSource,
      marketCache,
      const FakeIdGenerator(),
    );
    addTearDown(cubit.close);

    await expectLater(cubit.stream, emitsThrough(isA<AllocationError>()));
  });
}
