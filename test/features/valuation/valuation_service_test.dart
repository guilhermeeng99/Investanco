import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/fixed_income_terms_factory.dart';
import '../../harness/factories/holding_factory.dart';
import '../../harness/factories/index_point_factory.dart';
import '../../harness/factories/quote_factory.dart';

void main() {
  const service = ValuationService();
  const brl = Currency.brl;
  const usd = Currency.usd;
  final now = DateTime(2026, 5, 20, 12);

  test('fresh quote yields market value, unrealized P/L and return', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holdingFactory(),
        asset: assetFactory(),
        fxToBase: 1,
        quote: quoteFactory(
          unitPrice: Money.fromMajor(15, brl),
          asOf: now,
          fetchedAt: now,
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
      ValuationInput(holding: holdingFactory(), asset: assetFactory(), fxToBase: 1),
      now: now,
    );

    expect(result.priceStale, isTrue);
    expect(result.unrealizedPL, const Money.zero(brl));
    expect(result.marketValueBase, result.investedBase);
  });

  test('USD holding is consolidated to BRL via FX', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holdingFactory(quantity: 2, avgCost: const Money(1000, usd)),
        asset: assetFactory(
          currency: usd,
          market: Market.us,
          kind: AssetKind.stockUs,
        ),
        fxToBase: 5,
        quote: quoteFactory(
          unitPrice: Money.fromMajor(12, usd),
          asOf: now,
          fetchedAt: now,
        ),
      ),
      now: now,
    );

    // 12 USD * 2 * 5 = 120 BRL ; invested 10 USD * 2 * 5 = 100 BRL
    expect(result.marketValueBase, Money.fromMajor(120, brl));
    expect(result.investedBase, Money.fromMajor(100, brl));
    expect(result.unrealizedPL, Money.fromMajor(20, brl));
  });

  test('a foreign holding with no FX is zeroed and flagged fxMissing', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holdingFactory(quantity: 2, avgCost: const Money(1000, usd)),
        asset: assetFactory(
          currency: usd,
          market: Market.us,
          kind: AssetKind.stockUs,
        ),
        fxToBase: null, // rate unavailable — must not value at a bogus 1:1
        quote: quoteFactory(
          unitPrice: Money.fromMajor(12, usd),
          asOf: now,
          fetchedAt: now,
        ),
      ),
      now: now,
    );

    expect(result.fxMissing, isTrue);
    expect(result.priceStale, isTrue);
    expect(result.marketValueBase, const Money.zero(brl));
    expect(result.investedBase, const Money.zero(brl));
  });

  test('portfolio excludes an FX-missing foreign holding from totals', () {
    final portfolio = service.valuatePortfolio(
      [
        ValuationInput(
          holding: holdingFactory(quantity: 1, avgCost: const Money(800, brl)),
          asset: assetFactory(),
          fxToBase: 1,
          quote: quoteFactory(
            unitPrice: Money.fromMajor(10, brl),
            asOf: now,
            fetchedAt: now,
          ),
        ),
        ValuationInput(
          holding: holdingFactory(quantity: 2, avgCost: const Money(1000, usd)),
          asset: assetFactory(
            currency: usd,
            market: Market.us,
            kind: AssetKind.stockUs,
          ),
          fxToBase: null,
          quote: quoteFactory(
            unitPrice: Money.fromMajor(12, usd),
            asOf: now,
            fetchedAt: now,
          ),
        ),
      ],
      now: now,
    );

    // Both holdings are listed, but only the BRL one counts toward the total.
    expect(portfolio.holdings, hasLength(2));
    expect(portfolio.holdings.where((h) => h.fxMissing), hasLength(1));
    expect(portfolio.totalValueBase, Money.fromMajor(10, brl));
  });

  test('a quote older than the threshold is stale', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: holdingFactory(),
        asset: assetFactory(),
        fxToBase: 1,
        quote: quoteFactory(
          unitPrice: Money.fromMajor(11, brl),
          asOf: now.subtract(const Duration(hours: 2)),
          fetchedAt: now.subtract(const Duration(hours: 2)),
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
          holding: holdingFactory(),
          asset: assetFactory(id: 'a1'),
          fxToBase: 1,
          quote: quoteFactory(
            unitPrice: Money.fromMajor(15, brl),
            asOf: now,
            fetchedAt: now,
          ),
        ),
        ValuationInput(
          holding: holdingFactory(
            assetId: 'a2',
            quantity: 1,
            avgCost: Money.fromMajor(50, brl),
          ),
          asset: assetFactory(id: 'a2', kind: AssetKind.fiiBr),
          fxToBase: 1,
          quote: quoteFactory(
            assetId: 'a2',
            unitPrice: Money.fromMajor(60, brl),
            asOf: now,
            fetchedAt: now,
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

  // R$10,000 principal modeled as quantity 1 × avgCost 10,000.
  final fixedIncomeHolding =
      holdingFactory(quantity: 1, avgCost: const Money(1000000, brl));

  test('CDI accrual compounds daily rates scaled by the contracted percent', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: fixedIncomeHolding,
        asset: assetFactory(kind: AssetKind.fixedIncome),
        fxToBase: 1,
        fixedIncome: fixedIncomeTermsFactory(
          series: [
            indexPointFactory(date: DateTime(2026, 5, 4)),
            indexPointFactory(date: DateTime(2026, 5, 5)),
          ],
        ),
      ),
      now: now,
    );

    // (1 + 0.01)^2 = 1.0201 → 10000 * 1.0201 = 10201
    expect(result.marketValueBase, Money.fromMajor(10201, brl));
    expect(result.unrealizedPL, Money.fromMajor(201, brl));
    expect(result.priceStale, isFalse);
  });

  test('110% of CDI scales each daily rate by 1.10', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: fixedIncomeHolding,
        asset: assetFactory(kind: AssetKind.fixedIncome),
        fxToBase: 1,
        fixedIncome: fixedIncomeTermsFactory(
          ratePercent: 110,
          series: [indexPointFactory(date: DateTime(2026, 5, 4))],
        ),
      ),
      now: now,
    );

    // 1 + 0.01 * 1.10 = 1.011 → 10000 * 1.011 = 10110
    expect(result.marketValueBase, Money.fromMajor(10110, brl));
  });

  test('prefixed accrues by annual rate over business days (252)', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: fixedIncomeHolding,
        asset: assetFactory(kind: AssetKind.fixedIncome),
        fxToBase: 1,
        fixedIncome: fixedIncomeTermsFactory(
          basis: FixedIncomeBasis.prefixed,
          ratePercent: 10,
          purchaseDate: DateTime(2026, 5, 18), // Mon; 2 business days to Wed 20th
        ),
      ),
      now: now,
    );

    // 1.10^(2/252) ≈ 1.0007567 → ≈ R$10007.57
    expect(result.marketValueBase.major, closeTo(10007.57, 0.05));
  });

  test('IPCA+ multiplies accumulated inflation by the spread', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: fixedIncomeHolding,
        asset: assetFactory(kind: AssetKind.fixedIncome),
        fxToBase: 1,
        fixedIncome: fixedIncomeTermsFactory(
          basis: FixedIncomeBasis.ipca,
          ratePercent: 6,
          purchaseDate: DateTime(2026, 5, 18), // 2 business days to Wed 20th
          series: [indexPointFactory(date: DateTime(2026, 5, 19), rate: 0.5)],
        ),
      ),
      now: now,
    );

    // 1.005 * 1.06^(2/252) ≈ 1.0054649 → ≈ R$10054.65
    expect(result.marketValueBase.major, closeTo(10054.65, 0.1));
  });

  test('each contribution accrues from its own date (per-lot)', () {
    final result = service.valuateHolding(
      ValuationInput(
        // Two R$10k deposits → R$20k invested.
        holding:
            holdingFactory(quantity: 1, avgCost: const Money(2000000, brl)),
        asset: assetFactory(kind: AssetKind.fixedIncome),
        fxToBase: 1,
        fixedIncome: fixedIncomeTermsFactory(
          lots: [
            FixedIncomeLot(
              date: DateTime(2026, 5, 4),
              principal: const Money(1000000, brl),
            ),
            FixedIncomeLot(
              date: DateTime(2026, 5, 6),
              principal: const Money(1000000, brl),
            ),
          ],
          series: [
            indexPointFactory(date: DateTime(2026, 5, 4)),
            indexPointFactory(date: DateTime(2026, 5, 5)),
            indexPointFactory(date: DateTime(2026, 5, 6)),
          ],
        ),
      ),
      now: now,
    );

    // Lot A (05-04) catches all 3 days: 10000 * 1.01^3 = 10303.01.
    // Lot B (05-06) catches only the last: 10000 * 1.01 = 10100.
    expect(result.marketValueBase.major, closeTo(20403.01, 0.02));
    expect(result.investedBase, Money.fromMajor(20000, brl));
  });

  test('a present quote takes precedence over fixed-income terms', () {
    final result = service.valuateHolding(
      ValuationInput(
        holding: fixedIncomeHolding,
        asset: assetFactory(kind: AssetKind.fixedIncome),
        fxToBase: 1,
        quote: quoteFactory(
          unitPrice: Money.fromMajor(11000, brl),
          asOf: now,
          fetchedAt: now,
        ),
        fixedIncome: fixedIncomeTermsFactory(
          series: [indexPointFactory(date: DateTime(2026, 5, 4))],
        ),
      ),
      now: now,
    );

    // Quote 11000 × qty 1 wins; accrual ignored.
    expect(result.marketValueBase, Money.fromMajor(11000, brl));
  });
}
