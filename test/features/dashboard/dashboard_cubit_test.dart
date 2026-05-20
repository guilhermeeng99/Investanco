import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/fixed_income_metadata.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/institution_factory.dart';
import '../../harness/factories/transaction_factory.dart';

class _MockQuoteRepository extends Mock implements QuoteRepository {}

class _MockFxDataSource extends Mock implements FxDataSource {}

class _MockIndexDataSource extends Mock implements IndexDataSource {}

class _MockSnapshotRepository extends Mock implements SnapshotRepository {}

void main() {
  late AppDatabase db;
  late _MockQuoteRepository quoteRepository;
  late _MockFxDataSource fxDataSource;
  late _MockIndexDataSource indexDataSource;
  late _MockSnapshotRepository snapshotRepository;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(<Asset>[]);
    registerFallbackValue(const Money.zero(Currency.brl));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(EconomicIndex.cdi);
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    quoteRepository = _MockQuoteRepository();
    fxDataSource = _MockFxDataSource();
    indexDataSource = _MockIndexDataSource();
    snapshotRepository = _MockSnapshotRepository();

    // Seed a US position: 2 SOXX @ US$80 at Avenue.
    await InstitutionRepositoryImpl(db).save(
      institutionFactory(id: 'i1', name: 'Avenue', currency: Currency.usd),
    );
    await AssetRepositoryImpl(db).save(
      assetFactory(
        id: 'a1',
        ticker: 'SOXX',
        kind: AssetKind.stockUs,
        market: Market.us,
        currency: Currency.usd,
      ),
    );
    await TransactionRepositoryImpl(db).save(
      transactionFactory(
        id: 't1',
        institutionId: 'i1',
        assetId: 'a1',
        quantity: 2,
        unitPrice: Money.fromMajor(80, Currency.usd),
        fees: const Money.zero(Currency.usd),
        amount: Money.fromMajor(160, Currency.usd),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  DashboardCubit buildCubit() => DashboardCubit(
        TransactionRepositoryImpl(db),
        AssetRepositoryImpl(db),
        InstitutionRepositoryImpl(db),
        const HoldingCalculator(),
        quoteRepository,
        fxDataSource,
        const ValuationService(),
        snapshotRepository,
        indexDataSource,
      );

  test('builds a priced portfolio from local data + quote + FX', () async {
    final now = DateTime.now();
    final quote = Quote(
      assetId: 'a1',
      unitPrice: Money.fromMajor(100, Currency.usd),
      asOf: now,
      fetchedAt: now,
      source: QuoteSource.finnhub,
    );
    when(() => quoteRepository.getCached(any()))
        .thenAnswer((_) async => [quote]);
    when(() => quoteRepository.refresh(any()))
        .thenAnswer((_) async => Right([quote]));
    when(() => fxDataSource.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right<Failure, double>(5));
    when(() => snapshotRepository.range(any(), any()))
        .thenAnswer((_) async => <Snapshot>[]);
    when(
      () => snapshotRepository.upsertToday(
        totalValue: any(named: 'totalValue'),
        totalInvested: any(named: 'totalInvested'),
        totalPL: any(named: 'totalPL'),
      ),
    ).thenAnswer((_) async {});

    final cubit = buildCubit();
    addTearDown(cubit.close);

    // After refresh applies FX: 2 * US$100 * 5 = R$1000 value, R$200 profit.
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<DashboardState>((state) {
          if (state is! DashboardLoaded || state.portfolio.holdings.isEmpty) {
            return false;
          }
          final holding = state.portfolio.holdings.first;
          return !holding.priceStale &&
              holding.marketValueBase == Money.fromMajor(1000, Currency.brl) &&
              holding.unrealizedPL == Money.fromMajor(200, Currency.brl);
        }),
      ),
    );
  });

  test('accrues a CDI fixed-income holding from the index series', () async {
    // A R$10,000 CDB at 100% of CDI, bought long before the series window.
    await InstitutionRepositoryImpl(db).save(institutionFactory(id: 'i2'));
    await AssetRepositoryImpl(db).save(
      assetFactory(
        id: 'a2',
        ticker: 'CDB-NU',
        name: 'CDB Nubank',
        kind: AssetKind.fixedIncome,
        metadata: FixedIncomeMetadata.write(FixedIncomeBasis.cdi, 100),
      ),
    );
    await TransactionRepositoryImpl(db).save(
      transactionFactory(
        id: 't2',
        institutionId: 'i2',
        assetId: 'a2',
        unitPrice: Money.fromMajor(10000, Currency.brl),
        amount: Money.fromMajor(10000, Currency.brl),
        date: DateTime(2020),
      ),
    );

    when(() => quoteRepository.getCached(any())).thenAnswer((_) async => []);
    when(() => quoteRepository.refresh(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => fxDataSource.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right<Failure, double>(5));
    when(() => indexDataSource.series(any(), any())).thenAnswer(
      (_) async => Right([
        IndexPoint(date: DateTime(2020, 1, 2), rate: 1),
        IndexPoint(date: DateTime(2020, 1, 3), rate: 1),
      ]),
    );
    when(() => snapshotRepository.range(any(), any()))
        .thenAnswer((_) async => <Snapshot>[]);
    when(
      () => snapshotRepository.upsertToday(
        totalValue: any(named: 'totalValue'),
        totalInvested: any(named: 'totalInvested'),
        totalPL: any(named: 'totalPL'),
      ),
    ).thenAnswer((_) async {});

    final cubit = buildCubit();
    addTearDown(cubit.close);

    // (1 + 0.01)^2 = 1.0201 → 10000 * 1.0201 = 10201 ; profit 201.
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<DashboardState>((state) {
          if (state is! DashboardLoaded) return false;
          final fi =
              state.portfolio.holdings.where((h) => h.assetId == 'a2').toList();
          if (fi.isEmpty) return false;
          return !fi.first.priceStale &&
              fi.first.marketValueBase == Money.fromMajor(10201, Currency.brl) &&
              fi.first.unrealizedPL == Money.fromMajor(201, Currency.brl);
        }),
      ),
    );
  });
}
