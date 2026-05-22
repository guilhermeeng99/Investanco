import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/fixed_income_metadata.dart';
import 'package:investanco/features/valuation/domain/portfolio_inputs_builder.dart';

import '../../harness/factories/asset_factory.dart';
import '../../harness/factories/holding_factory.dart';
import '../../harness/factories/index_point_factory.dart';
import '../../harness/factories/quote_factory.dart';
import '../../harness/factories/transaction_factory.dart';

void main() {
  const builder = PortfolioInputsBuilder();

  group('build', () {
    test('a BRL holding gets fxToBase 1.0', () {
      final inputs = builder.build(
        holdings: [holdingFactory(assetId: 'a1')],
        assetsById: {'a1': assetFactory(id: 'a1', currency: Currency.brl)},
        transactions: const [],
        quotesById: const {},
        indexSeries: const {},
        fxUsdToBrl: 5,
      );
      expect(inputs.single.fxToBase, 1.0);
    });

    test('a USD holding gets the USD→BRL rate when loaded', () {
      final asset = assetFactory(
        id: 'a1',
        kind: AssetKind.stockUs,
        market: Market.us,
        currency: Currency.usd,
      );
      final inputs = builder.build(
        holdings: [holdingFactory(assetId: 'a1')],
        assetsById: {'a1': asset},
        transactions: const [],
        quotesById: const {},
        indexSeries: const {},
        fxUsdToBrl: 5,
      );
      expect(inputs.single.fxToBase, 5);
    });

    test('a USD holding gets a null FX when the rate is not loaded', () {
      final asset = assetFactory(
        id: 'a1',
        kind: AssetKind.stockUs,
        market: Market.us,
        currency: Currency.usd,
      );
      final inputs = builder.build(
        holdings: [holdingFactory(assetId: 'a1')],
        assetsById: {'a1': asset},
        transactions: const [],
        quotesById: const {},
        indexSeries: const {},
        fxUsdToBrl: null,
      );
      expect(inputs.single.fxToBase, isNull);
    });

    test('attaches the cached quote and skips holdings with no asset', () {
      final quote = quoteFactory(assetId: 'a1');
      final inputs = builder.build(
        holdings: [
          holdingFactory(assetId: 'a1'),
          holdingFactory(assetId: 'ghost'),
        ],
        assetsById: {'a1': assetFactory(id: 'a1', currency: Currency.brl)},
        transactions: const [],
        quotesById: {'a1': quote},
        indexSeries: const {},
        fxUsdToBrl: 1,
      );
      expect(inputs.length, 1);
      expect(inputs.single.quote, quote);
    });

    test('builds fixed-income terms from metadata and the buy cash flow', () {
      final asset = assetFactory(
        id: 'a1',
        kind: AssetKind.fixedIncome,
        currency: Currency.brl,
        metadata: FixedIncomeMetadata.write(FixedIncomeBasis.cdi, 100),
      );
      final inputs = builder.build(
        holdings: [holdingFactory(assetId: 'a1', quantity: 1)],
        assetsById: {'a1': asset},
        transactions: [
          transactionFactory(
            id: 't1',
            assetId: 'a1',
            institutionId: 'i1',
            unitPrice: Money.fromMajor(1000, Currency.brl),
            amount: Money.fromMajor(1000, Currency.brl),
            date: DateTime(2020),
          ),
        ],
        quotesById: const {},
        indexSeries: {
          EconomicIndex.cdi: [
            indexPointFactory(date: DateTime(2020, 1, 2), rate: 1),
          ],
        },
        fxUsdToBrl: 1,
      );
      final terms = inputs.single.fixedIncome;
      expect(terms, isNotNull);
      expect(terms!.basis, FixedIncomeBasis.cdi);
      expect(terms.ratePercent, 100);
      expect(terms.cashFlows, isNotEmpty);
      expect(terms.series, isNotEmpty);
    });

    test('a non-fixed-income holding has null terms', () {
      final asset = assetFactory(
        id: 'a1',
        kind: AssetKind.stockBr,
        currency: Currency.brl,
      );
      final inputs = builder.build(
        holdings: [holdingFactory(assetId: 'a1')],
        assetsById: {'a1': asset},
        transactions: const [],
        quotesById: const {},
        indexSeries: const {},
        fxUsdToBrl: 1,
      );
      expect(inputs.single.fixedIncome, isNull);
    });
  });

  group('heldAssetIds', () {
    test('includes open positions and fixed income with transactions', () {
      final ids = builder.heldAssetIds(
        [
          holdingFactory(assetId: 'a1', quantity: 5),
          holdingFactory(assetId: 'a2', quantity: 0), // closed FI
        ],
        [
          assetFactory(id: 'a1', kind: AssetKind.stockBr),
          assetFactory(id: 'a2', kind: AssetKind.fixedIncome),
        ],
        [transactionFactory(id: 't1', assetId: 'a2', institutionId: 'i1')],
      );
      expect(ids, {'a1', 'a2'});
    });

    test('excludes a closed market position', () {
      final ids = builder.heldAssetIds(
        [holdingFactory(assetId: 'a1', quantity: 0)],
        [assetFactory(id: 'a1', kind: AssetKind.stockBr)],
        const [],
      );
      expect(ids, isEmpty);
    });
  });

  group('earliestIndexDates', () {
    test('takes the earliest buy per index across positions', () {
      final fi = assetFactory(
        id: 'a1',
        kind: AssetKind.fixedIncome,
        metadata: FixedIncomeMetadata.write(FixedIncomeBasis.cdi, 100),
      );
      final dates = builder.earliestIndexDates(
        [fi],
        [
          transactionFactory(
            id: 't1',
            assetId: 'a1',
            institutionId: 'i1',
            date: DateTime(2022, 6),
          ),
          transactionFactory(
            id: 't2',
            assetId: 'a1',
            institutionId: 'i1',
            date: DateTime(2020),
          ),
        ],
      );
      expect(dates[EconomicIndex.cdi], DateTime(2020));
    });

    test('ignores prefixed (needs no index series)', () {
      final fi = assetFactory(
        id: 'a1',
        kind: AssetKind.fixedIncome,
        metadata: FixedIncomeMetadata.write(FixedIncomeBasis.prefixed, 12),
      );
      final dates = builder.earliestIndexDates(
        [fi],
        [
          transactionFactory(
            id: 't1',
            assetId: 'a1',
            institutionId: 'i1',
            date: DateTime(2020),
          ),
        ],
      );
      expect(dates, isEmpty);
    });
  });
}
