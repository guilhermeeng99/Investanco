import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:investanco/features/valuation/presentation/portfolio_pricing_engine.dart';
import 'package:mocktail/mocktail.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/mocks.dart';

// Unit-level coverage of the shared engine's branches that the dashboard/
// allocation integration tests only exercise indirectly: freshness shortcuts
// and the network refresh's FX persistence.
void main() {
  late MockQuoteRepository quoteRepository;
  late MockFxDataSource fxDataSource;
  late MockIndexDataSource indexDataSource;
  late MockMarketCacheStore cacheStore;

  PortfolioPricingEngine build() => PortfolioPricingEngine(
        quoteRepository,
        fxDataSource,
        const ValuationService(),
        indexDataSource,
        cacheStore,
        const HoldingCalculator(),
      );

  setUp(() {
    quoteRepository = MockQuoteRepository();
    fxDataSource = MockFxDataSource();
    indexDataSource = MockIndexDataSource();
    cacheStore = MockMarketCacheStore();
  });

  final usAsset = assetFactory(
    currency: Currency.usd,
    market: Market.us,
    kind: AssetKind.stockUs,
  );

  group('quotesAreFresh', () {
    test('is true for an empty held set without touching the repository',
        () async {
      expect(await build().quotesAreFresh(<String>{}), isTrue);
      verifyNever(() => quoteRepository.lastFetchedAt(any()));
    });

    test('is true within the freshness window', () async {
      when(() => quoteRepository.lastFetchedAt(any()))
          .thenAnswer((_) async => DateTime.now());

      expect(await build().quotesAreFresh({'a1'}), isTrue);
    });

    test('is false once the last fetch is older than the window', () async {
      when(() => quoteRepository.lastFetchedAt(any())).thenAnswer(
        (_) async => DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(await build().quotesAreFresh({'a1'}), isFalse);
    });

    test('is false when nothing has ever been fetched', () async {
      when(() => quoteRepository.lastFetchedAt(any()))
          .thenAnswer((_) async => null);

      expect(await build().quotesAreFresh({'a1'}), isFalse);
    });
  });

  group('refreshNetwork', () {
    test('persists the fetched USD→BRL rate when a foreign asset is held',
        () async {
      when(() => quoteRepository.refresh(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => fxDataSource.rate(Currency.usd, Currency.brl))
          .thenAnswer((_) async => const Right<Failure, double>(5));
      when(() => cacheStore.saveFxRate(Currency.usd, Currency.brl, any()))
          .thenAnswer((_) async {});

      await build().refreshNetwork([usAsset], const []);

      verify(() => cacheStore.saveFxRate(Currency.usd, Currency.brl, 5))
          .called(1);
    });

    test('does not fetch FX for a BRL-only portfolio', () async {
      when(() => quoteRepository.refresh(any()))
          .thenAnswer((_) async => const Right([]));

      await build().refreshNetwork([assetFactory()], const []);

      verifyNever(() => fxDataSource.rate(Currency.usd, Currency.brl));
    });

    test('leaves FX unpersisted when the rate fetch fails', () async {
      when(() => quoteRepository.refresh(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => fxDataSource.rate(Currency.usd, Currency.brl))
          .thenAnswer((_) async => const Left<Failure, double>(NetworkFailure()));

      await build().refreshNetwork([usAsset], const []);

      verifyNever(
        () => cacheStore.saveFxRate(Currency.usd, Currency.brl, any()),
      );
    });
  });
}
