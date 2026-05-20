import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/holdings/domain/entities/holding.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';

import '../../harness/factories/asset_factory.dart';

void main() {
  const service = ValuationService();
  const brl = Currency.brl;
  const usd = Currency.usd;
  final now = DateTime(2026, 5, 20, 12);

  Holding holding({
    double quantity = 10,
    Money avgCost = const Money(1000, brl),
    Money realized = const Money(0, brl),
    Money dividends = const Money(0, brl),
  }) {
    return Holding(
      assetId: 'a1',
      institutionId: 'i1',
      quantity: quantity,
      avgCost: avgCost,
      realizedPL: realized,
      dividends: dividends,
    );
  }

  test('fresh quote yields market value, unrealized P/L and return', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holding(),
        asset: assetFactory(),
        fxToBase: 1,
        quote: Quote(
          assetId: 'a1',
          unitPrice: Money.fromMajor(15, brl),
          asOf: now,
          fetchedAt: now,
          source: QuoteSource.brapi,
        ),
      ),
      now: now,
    );

    expect(result.marketValueBase, Money.fromMajor(150, brl));
    expect(result.investedBase, Money.fromMajor(100, brl));
    expect(result.unrealizedPL, Money.fromMajor(50, brl));
    expect(result.returnPct, 0.5);
    expect(result.priceStale, isFalse);
  });

  test('missing quote falls back to invested and flags stale', () {
    final result = service.valuateHolding(
      ValuationInput(holding: holding(), asset: assetFactory(), fxToBase: 1),
      now: now,
    );

    expect(result.priceStale, isTrue);
    expect(result.unrealizedPL, const Money.zero(brl));
    expect(result.marketValueBase, result.investedBase);
  });

  test('USD holding is consolidated to BRL via FX', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holding(quantity: 2, avgCost: const Money(1000, usd)),
        asset: assetFactory(
          currency: usd,
          market: Market.us,
          kind: AssetKind.stockUs,
        ),
        fxToBase: 5,
        quote: Quote(
          assetId: 'a1',
          unitPrice: Money.fromMajor(12, usd),
          asOf: now,
          fetchedAt: now,
          source: QuoteSource.yahoo,
        ),
      ),
      now: now,
    );

    // 12 USD * 2 * 5 = 120 BRL ; invested 10 USD * 2 * 5 = 100 BRL
    expect(result.marketValueBase, Money.fromMajor(120, brl));
    expect(result.investedBase, Money.fromMajor(100, brl));
    expect(result.unrealizedPL, Money.fromMajor(20, brl));
  });

  test('a quote older than the threshold is stale', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holding(),
        asset: assetFactory(),
        fxToBase: 1,
        quote: Quote(
          assetId: 'a1',
          unitPrice: Money.fromMajor(11, brl),
          asOf: now.subtract(const Duration(hours: 2)),
          fetchedAt: now.subtract(const Duration(hours: 2)),
          source: QuoteSource.brapi,
        ),
      ),
      now: now,
    );

    expect(result.priceStale, isTrue);
  });

  test('portfolio aggregates totals and allocation by class', () {
    final portfolio = service.valuatePortfolio(
      [
        ValuationInput(
          holding: holding(),
          asset: assetFactory(id: 'a1'),
          fxToBase: 1,
          quote: Quote(
            assetId: 'a1',
            unitPrice: Money.fromMajor(15, brl),
            asOf: now,
            fetchedAt: now,
            source: QuoteSource.brapi,
          ),
        ),
        ValuationInput(
          holding: Holding(
            assetId: 'a2',
            institutionId: 'i1',
            quantity: 1,
            avgCost: Money.fromMajor(50, brl),
            realizedPL: const Money.zero(brl),
            dividends: const Money.zero(brl),
          ),
          asset: assetFactory(id: 'a2', kind: AssetKind.fiiBr),
          fxToBase: 1,
          quote: Quote(
            assetId: 'a2',
            unitPrice: Money.fromMajor(60, brl),
            asOf: now,
            fetchedAt: now,
            source: QuoteSource.brapi,
          ),
        ),
      ],
      now: now,
    );

    expect(portfolio.totalValueBase, Money.fromMajor(210, brl)); // 150 + 60
    expect(portfolio.totalInvestedBase, Money.fromMajor(150, brl)); // 100 + 50
    expect(portfolio.totalUnrealizedPL, Money.fromMajor(60, brl)); // 50 + 10
    expect(portfolio.byClass[AssetKind.stockBr], Money.fromMajor(150, brl));
    expect(portfolio.byClass[AssetKind.fiiBr], Money.fromMajor(60, brl));
  });
}
