import 'package:dartz/dartz.dart';
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
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/fixed_income_metadata.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/index_point_factory.dart';
import '../../harness/factories/institution_factory.dart';
import '../../harness/factories/quote_factory.dart';
import '../../harness/factories/transaction_factory.dart';
import '../../harness/helpers.dart';
import '../../harness/mocks.dart';

// Integration-style test: the cubit runs against real local repositories over an
// in-memory Drift db, while the network-backed sources (quotes, FX, index,
// snapshot writes) are mocked at their boundary.
void main() {
  late AppDatabase db;
  late MockQuoteRepository quoteRepository;
  late MockFxDataSource fxDataSource;
  late MockIndexDataSource indexDataSource;
  late MockSnapshotRepository snapshotRepository;

  setUp(() async {
    db = memoryDatabase();
    quoteRepository = MockQuoteRepository();
    fxDataSource = MockFxDataSource();
    indexDataSource = MockIndexDataSource();
    snapshotRepository = MockSnapshotRepository();

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
    final quote = quoteFactory(
      unitPrice: Money.fromMajor(100, Currency.usd),
      asOf: now,
      fetchedAt: now,
      source: QuoteSource.finnhub,
    );
    when(() => quoteRepository.getCached(any()))
        .thenAnswer((_) async => Right([quote]));
    when(() => quoteRepository.refresh(any()))
        .thenAnswer((_) async => Right([quote]));
    when(() => fxDataSource.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right<Failure, double>(5));
    when(() => snapshotRepository.range(any(), any()))
        .thenAnswer((_) async => const Right(<Snapshot>[]));
    when(
      () => snapshotRepository.upsertToday(
        totalValue: any(named: 'totalValue'),
        totalInvested: any(named: 'totalInvested'),
        totalPL: any(named: 'totalPL'),
      ),
    ).thenAnswer((_) async => const Right(unit));

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

    when(() => quoteRepository.getCached(any()))
        .thenAnswer((_) async => const Right(<Quote>[]));
    when(() => quoteRepository.refresh(any()))
        .thenAnswer((_) async => const Right([]));
    when(() => fxDataSource.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right<Failure, double>(5));
    when(() => indexDataSource.series(any(), any())).thenAnswer(
      (_) async => Right([
        indexPointFactory(date: DateTime(2020, 1, 2), rate: 1),
        indexPointFactory(date: DateTime(2020, 1, 3), rate: 1),
      ]),
    );
    when(() => snapshotRepository.range(any(), any()))
        .thenAnswer((_) async => const Right(<Snapshot>[]));
    when(
      () => snapshotRepository.upsertToday(
        totalValue: any(named: 'totalValue'),
        totalInvested: any(named: 'totalInvested'),
        totalPL: any(named: 'totalPL'),
      ),
    ).thenAnswer((_) async => const Right(unit));

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

  /// Adds a second open position at a BR institution (Nubank), so the dashboard
  /// has two institutions to filter between. Stubs all network sources empty.
  Future<void> seedSecondInstitution() async {
    await InstitutionRepositoryImpl(db).save(
      institutionFactory(id: 'i2', name: 'Nubank'),
    );
    await AssetRepositoryImpl(db).save(
      assetFactory(
        id: 'a2',
        ticker: 'PETR4',
        kind: AssetKind.stockBr,
        market: Market.br,
        currency: Currency.brl,
      ),
    );
    await TransactionRepositoryImpl(db).save(
      transactionFactory(
        id: 't2',
        institutionId: 'i2',
        assetId: 'a2',
        quantity: 10,
        unitPrice: Money.fromMajor(10, Currency.brl),
        fees: const Money.zero(Currency.brl),
        amount: Money.fromMajor(100, Currency.brl),
      ),
    );

    when(() => quoteRepository.getCached(any()))
        .thenAnswer((_) async => const Right(<Quote>[]));
    when(() => quoteRepository.refresh(any()))
        .thenAnswer((_) async => const Right(<Quote>[]));
    when(() => fxDataSource.rate(Currency.usd, Currency.brl))
        .thenAnswer((_) async => const Right<Failure, double>(5));
    when(() => snapshotRepository.range(any(), any()))
        .thenAnswer((_) async => const Right(<Snapshot>[]));
    when(
      () => snapshotRepository.upsertToday(
        totalValue: any(named: 'totalValue'),
        totalInvested: any(named: 'totalInvested'),
        totalPL: any(named: 'totalPL'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  }

  test('setInstitutionFilter scopes the visible portfolio to one institution',
      () async {
    await seedSecondInstitution();
    final cubit = buildCubit();
    addTearDown(cubit.close);

    // Wait until FX has loaded and both institutions count toward the portfolio.
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<DashboardState>(
          (s) => s is DashboardLoaded && s.portfolio.byInstitution.length == 2,
        ),
      ),
    );

    cubit.setInstitutionFilter('i2');
    final state = cubit.state as DashboardLoaded;

    expect(state.institutionFilter, 'i2');
    expect(state.filterableInstitutionIds.toSet(), {'i1', 'i2'});
    expect(
      state.visiblePortfolio.holdings
          .where((h) => h.quantity > 0)
          .map((h) => h.assetId),
      ['a2'],
    );
    expect(state.hasVisibleHoldings, isTrue);
  });

  test('clears the filter when its institution no longer holds value', () async {
    await seedSecondInstitution();
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<DashboardState>(
          (s) => s is DashboardLoaded && s.portfolio.byInstitution.length == 2,
        ),
      ),
    );
    cubit.setInstitutionFilter('i2');
    expect((cubit.state as DashboardLoaded).institutionFilter, 'i2');

    // Removing Nubank's only position drops i2 from the portfolio → reset to all.
    await TransactionRepositoryImpl(db).delete('t2');
    await expectLater(
      cubit.stream,
      emitsThrough(
        predicate<DashboardState>(
          (s) => s is DashboardLoaded && s.institutionFilter == null,
        ),
      ),
    );
  });
}
