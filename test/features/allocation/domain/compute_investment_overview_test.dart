import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/allocation/domain/asset_allocation.dart';
import 'package:investanco/features/allocation/domain/entities/investment_overview.dart';
import 'package:investanco/features/allocation/domain/services/compute_investment_overview.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

import '../../../harness/factories/asset_class_factory.dart';
import '../../../harness/factories/asset_factory.dart';
import '../../../harness/factories/holding_valuation_factory.dart';

void main() {
  const brl = Currency.brl;

  Asset asset(
    String id, {
    String? classId,
    double target = 0,
    Currency currency = Currency.brl,
    AssetKind kind = AssetKind.stockBr,
    Market market = Market.br,
  }) => assetFactory(
    id: id,
    ticker: id,
    currency: currency,
    kind: kind,
    market: market,
    metadata: classId == null
        ? const {}
        : {allocationClassIdKey: classId, allocationTargetKey: '$target'},
  );

  HoldingValuation holding(
    String assetId,
    double valueMajor, {
    Money? nativeValue,
    bool fxMissing = false,
  }) {
    final value = Money.fromMajor(valueMajor, brl);
    return holdingValuationFactory(
      assetId: assetId,
      marketValueBase: value,
      marketValueNative: nativeValue ?? value,
      investedBase: value,
      fxMissing: fxMissing,
    );
  }

  group('computeInvestmentOverview', () {
    test('empty input yields an empty overview', () {
      final overview = computeInvestmentOverview(
        classes: const [],
        assets: const [],
        holdings: const [],
        base: brl,
      );

      expect(overview.total, const Money.zero(brl));
      expect(overview.classes, isEmpty);
      expect(overview.rebalanceActions, isEmpty);
      expect(overview.hasInvestments, isFalse);
    });

    test('unassigned assets count as pending', () {
      final overview = computeInvestmentOverview(
        classes: [assetClassFactory(id: 'eq', targetPercent: 100)],
        assets: [
          asset('a1', classId: 'eq', target: 100),
          asset('a2'),
        ],
        holdings: [holding('a1', 600), holding('a2', 200)],
        base: brl,
      );

      expect(overview.total, Money.fromMajor(800, brl));
      expect(overview.allocated, Money.fromMajor(600, brl));
      expect(overview.pending, Money.fromMajor(200, brl));
      expect(overview.hasPending, isTrue);
    });

    test('computes per-class current %, delta and the rebalance plan', () {
      final overview = computeInvestmentOverview(
        classes: [
          assetClassFactory(id: 'eq', targetPercent: 60),
          assetClassFactory(id: 'fi', targetPercent: 40),
        ],
        assets: [
          asset('a1', classId: 'eq', target: 100),
          asset('a2', classId: 'fi', target: 100),
        ],
        holdings: [holding('a1', 600), holding('a2', 200)],
        base: brl,
      );

      final eq = overview.classes.firstWhere((c) => c.id == 'eq');
      final fi = overview.classes.firstWhere((c) => c.id == 'fi');

      // total 800: eq 600 (75%, target 480 → 120 over → sell);
      //            fi 200 (25%, target 320 → 120 under → buy).
      expect(eq.currentValue, Money.fromMajor(600, brl));
      expect(eq.currentPercent, closeTo(0.75, 1e-9));
      expect(eq.deltaValue, Money.fromMajor(-120, brl));
      expect(eq.isOverTarget, isTrue);
      expect(fi.deltaValue, Money.fromMajor(120, brl));
      expect(fi.isUnderTarget, isTrue);
      expect(overview.targetSumPercent, 100);

      expect(overview.rebalanceActions, hasLength(2));
      final buy = overview.rebalanceActions.firstWhere(
        (a) => a.direction == RebalanceDirection.buy,
      );
      final sell = overview.rebalanceActions.firstWhere(
        (a) => a.direction == RebalanceDirection.sell,
      );
      expect(buy.classId, 'fi');
      expect(buy.amount, Money.fromMajor(120, brl));
      expect(sell.classId, 'eq');
      expect(sell.amount, Money.fromMajor(120, brl));
    });

    test('lists the class assets with per-asset suggestion', () {
      final overview = computeInvestmentOverview(
        classes: [assetClassFactory(id: 'eq', targetPercent: 100)],
        assets: [
          asset('a1', classId: 'eq', target: 50),
          asset('a2', classId: 'eq', target: 50),
        ],
        holdings: [holding('a1', 300), holding('a2', 100)],
        base: brl,
      );

      final eq = overview.classes.single;
      expect(eq.currentValue, Money.fromMajor(400, brl));
      expect(eq.deltaValue, const Money.zero(brl));
      expect(eq.subclasses, hasLength(2));

      final a1 = eq.subclasses.firstWhere((s) => s.id == 'a1');
      final a2 = eq.subclasses.firstWhere((s) => s.id == 'a2');
      // class target 400; each asset target 50% → suggested 200.
      expect(a1.name, 'a1');
      expect(a1.currentValue, Money.fromMajor(300, brl));
      expect(a1.percentOfClass, closeTo(0.75, 1e-9));
      expect(a1.suggestedValue, Money.fromMajor(200, brl));
      expect(a1.suggestedDelta, Money.fromMajor(-100, brl)); // trim
      expect(a1.suggestedDeltaNative, isNull);
      expect(a2.suggestedDelta, Money.fromMajor(100, brl)); // add
    });

    test('adds native-currency deltas for foreign asset suggestions', () {
      final overview = computeInvestmentOverview(
        classes: [assetClassFactory(id: 'real-estate', targetPercent: 100)],
        assets: [
          asset(
            'VNQ',
            classId: 'real-estate',
            target: 50,
            currency: Currency.usd,
            kind: AssetKind.etfUs,
            market: Market.us,
          ),
          asset(
            'VNQI',
            classId: 'real-estate',
            target: 50,
            currency: Currency.usd,
            kind: AssetKind.etfUs,
            market: Market.us,
          ),
        ],
        holdings: [
          holding(
            'VNQ',
            600,
            nativeValue: Money.fromMajor(100, Currency.usd),
          ),
          holding(
            'VNQI',
            200,
            nativeValue: Money.fromMajor(40, Currency.usd),
          ),
        ],
        base: brl,
      );

      final vnq = overview.classes.single.subclasses.firstWhere(
        (s) => s.id == 'VNQ',
      );
      final vnqi = overview.classes.single.subclasses.firstWhere(
        (s) => s.id == 'VNQI',
      );

      // total/class target 800; each ETF target 400.
      expect(vnq.suggestedDelta, Money.fromMajor(-200, brl));
      expect(vnq.suggestedDeltaNative, Money.fromMajor(-33.33, Currency.usd));
      expect(vnqi.suggestedDelta, Money.fromMajor(200, brl));
      expect(vnqi.suggestedDeltaNative, Money.fromMajor(40, Currency.usd));
    });

    test('excludes fx-missing holdings from the total', () {
      final overview = computeInvestmentOverview(
        classes: [assetClassFactory(id: 'eq', targetPercent: 100)],
        assets: [
          asset('a1', classId: 'eq', target: 100),
          asset('a2', classId: 'eq', target: 0),
        ],
        holdings: [holding('a1', 600), holding('a2', 200, fxMissing: true)],
        base: brl,
      );

      expect(overview.total, Money.fromMajor(600, brl));
      expect(overview.classes.single.currentValue, Money.fromMajor(600, brl));
    });

    test(r'a gap under R$1 (50 minor) is noise — no rebalance action', () {
      final overview = computeInvestmentOverview(
        classes: [
          assetClassFactory(id: 'eq', targetPercent: 50),
          assetClassFactory(id: 'fi', targetPercent: 50),
        ],
        assets: [
          asset('a1', classId: 'eq', target: 100),
          asset('a2', classId: 'fi', target: 100),
        ],
        // total 20.00: eq 10.50 (target 10.00 → R$0.50 over); fi 9.50 (under).
        holdings: [holding('a1', 10.5), holding('a2', 9.5)],
        base: brl,
      );

      final eq = overview.classes.firstWhere((c) => c.id == 'eq');
      expect(eq.deltaValue, Money.fromMajor(-0.5, brl)); // R$0.50 < R$1
      expect(overview.rebalanceActions, isEmpty);
    });

    test(
      r'a gap of exactly R$1 crosses the threshold and produces an action',
      () {
        final overview = computeInvestmentOverview(
          classes: [
            assetClassFactory(id: 'eq', targetPercent: 50),
            assetClassFactory(id: 'fi', targetPercent: 50),
          ],
          assets: [
            asset('a1', classId: 'eq', target: 100),
            asset('a2', classId: 'fi', target: 100),
          ],
          // total 20.00: eq 11.00 (target 10.00 → R$1.00 over → sell); fi buy.
          holdings: [holding('a1', 11), holding('a2', 9)],
          base: brl,
        );

        expect(overview.rebalanceActions, hasLength(2));
        final sell = overview.rebalanceActions.firstWhere(
          (a) => a.direction == RebalanceDirection.sell,
        );
        expect(sell.classId, 'eq');
        expect(sell.amount, Money.fromMajor(1, brl)); // R$1 boundary → action
      },
    );

    test('excludes a non-root subclass from the slices and target sum', () {
      final overview = computeInvestmentOverview(
        classes: [
          assetClassFactory(id: 'eq', targetPercent: 60),
          assetClassFactory(id: 'sub', parentId: 'eq', targetPercent: 40),
        ],
        assets: [asset('a1', classId: 'eq', target: 100)],
        holdings: [holding('a1', 100)],
        base: brl,
      );

      // Only roots become top-level slices; the subclass target is not summed.
      expect(overview.classes.map((c) => c.id), ['eq']);
      expect(overview.targetSumPercent, 60);
    });
  });
}
