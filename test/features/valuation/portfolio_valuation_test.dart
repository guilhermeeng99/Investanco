import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';

import '../../harness/factories/holding_valuation_factory.dart';

void main() {
  const brl = Currency.brl;
  const usd = Currency.usd;

  group('PortfolioValuation.fromHoldings', () {
    test('aggregates totals across holdings', () {
      final portfolio = PortfolioValuation.fromHoldings(
        [
          holdingValuationFactory(
            institutionId: 'i1',
            marketValueBase: Money.fromMajor(100, brl),
            investedBase: Money.fromMajor(80, brl),
          ),
          holdingValuationFactory(
            assetId: 'a2',
            institutionId: 'i2',
            marketValueBase: Money.fromMajor(200, brl),
            investedBase: Money.fromMajor(150, brl),
          ),
        ],
        brl,
      );

      expect(portfolio.totalValueBase, Money.fromMajor(300, brl));
      expect(portfolio.totalInvestedBase, Money.fromMajor(230, brl));
      expect(portfolio.totalUnrealizedPL, Money.fromMajor(70, brl));
    });

    test('byCurrency sums native value per currency', () {
      final portfolio = PortfolioValuation.fromHoldings(
        [
          holdingValuationFactory(
            institutionId: 'i1',
            marketValueBase: Money.fromMajor(500, brl),
            marketValueNative: Money.fromMajor(500, brl),
          ),
          holdingValuationFactory(
            assetId: 'a2',
            institutionId: 'i2',
            marketValueBase: Money.fromMajor(1000, brl),
            marketValueNative: Money.fromMajor(200, usd),
          ),
        ],
        brl,
      );

      expect(portfolio.byCurrency[brl], Money.fromMajor(500, brl));
      expect(portfolio.byCurrency[usd], Money.fromMajor(200, usd));
    });

    test('excludes FX-missing holdings from totals and byCurrency', () {
      final portfolio = PortfolioValuation.fromHoldings(
        [
          holdingValuationFactory(
            marketValueBase: Money.fromMajor(100, brl),
          ),
          holdingValuationFactory(
            assetId: 'a2',
            fxMissing: true,
            marketValueBase: const Money.zero(brl),
            marketValueNative: Money.fromMajor(50, usd),
          ),
        ],
        brl,
      );

      expect(portfolio.totalValueBase, Money.fromMajor(100, brl));
      expect(portfolio.byCurrency.containsKey(usd), isFalse);
      // The holding is still listed so the UI can warn about it.
      expect(portfolio.holdings, hasLength(2));
    });
  });

  group('forInstitution', () {
    final portfolio = PortfolioValuation.fromHoldings(
      [
        holdingValuationFactory(
          assetId: 'a1',
          institutionId: 'i1',
          marketValueBase: Money.fromMajor(100, brl),
          investedBase: Money.fromMajor(80, brl),
        ),
        holdingValuationFactory(
          assetId: 'a2',
          institutionId: 'i2',
          marketValueBase: Money.fromMajor(200, brl),
          investedBase: Money.fromMajor(150, brl),
        ),
      ],
      brl,
    );

    test('narrows totals and holdings to one institution', () {
      final only = portfolio.forInstitution('i2');

      expect(only.totalValueBase, Money.fromMajor(200, brl));
      expect(only.totalInvestedBase, Money.fromMajor(150, brl));
      expect(only.holdings.map((h) => h.assetId), ['a2']);
    });

    test('null filter returns the same instance', () {
      expect(identical(portfolio.forInstitution(null), portfolio), isTrue);
    });
  });
}
