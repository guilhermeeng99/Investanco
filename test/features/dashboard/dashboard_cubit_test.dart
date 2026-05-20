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
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/institution_factory.dart';
import '../../harness/factories/transaction_factory.dart';

class _MockQuoteRepository extends Mock implements QuoteRepository {}

class _MockFxDataSource extends Mock implements FxDataSource {}

class _MockSnapshotRepository extends Mock implements SnapshotRepository {}

void main() {
  late AppDatabase db;
  late _MockQuoteRepository quoteRepository;
  late _MockFxDataSource fxDataSource;
  late _MockSnapshotRepository snapshotRepository;

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(<Asset>[]);
    registerFallbackValue(const Money.zero(Currency.brl));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    quoteRepository = _MockQuoteRepository();
    fxDataSource = _MockFxDataSource();
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
}
