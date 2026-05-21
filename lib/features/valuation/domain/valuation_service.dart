import 'dart:math';

import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/holdings/domain/entities/holding.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';
import 'package:investanco/features/valuation/domain/entities/portfolio_valuation.dart';

/// One holding plus the data needed to price it.
class ValuationInput {
  /// Creates an input row.
  const ValuationInput({
    required this.holding,
    required this.asset,
    required this.fxToBase,
    this.quote,
    this.fixedIncome,
  });

  /// The position.
  final Holding holding;

  /// Its asset (for currency/class).
  final Asset asset;

  /// Latest quote, or null when unavailable.
  final Quote? quote;

  /// Accrual terms for fixed income; null for market-priced assets. Used only
  /// when [quote] is null, to value the holding by index/rate accrual instead of
  /// falling back to cost.
  final FixedIncomeTerms? fixedIncome;

  /// Multiplier converting the asset's currency to the base currency (1.0 when
  /// already in base). **Null** means the rate is unavailable for a foreign
  /// holding — it's then excluded from totals and flagged, never valued at a
  /// bogus 1:1. See `docs/specs/valuation.md`.
  final double? fxToBase;
}

/// Pure valuation math. Turns holdings + quotes + FX into money figures
/// consolidated to the base currency. See `docs/specs/valuation.md`.
class ValuationService {
  /// Creates the service.
  const ValuationService();

  /// A quote older than this is considered stale.
  static const Duration defaultStaleThreshold = Duration(hours: 1);

  /// Values a single holding.
  HoldingValuation valuateHolding(
    ValuationInput input, {
    required DateTime now,
    Currency base = Currency.brl,
    Duration staleThreshold = defaultStaleThreshold,
  }) {
    final holding = input.holding;
    final fx = input.fxToBase;

    // A foreign holding with no FX rate can't be consolidated to base — exclude
    // it (zeroed + flagged) instead of valuing at a bogus 1:1. valuatePortfolio
    // skips it from totals; the UI warns. See `docs/specs/valuation.md`.
    if (input.asset.currency != base && fx == null) {
      return _unvaluable(input, base);
    }
    final rate = fx ?? 1.0;

    final investedBase = _toBase(holding.investedCost, rate, base);
    final (marketValueBase, unrealizedPL, stale) =
        _price(input, investedBase, rate, now, base, staleThreshold);

    final realizedBase = _toBase(holding.realizedPL, rate, base);
    final dividendsBase = _toBase(holding.dividends, rate, base);
    final totalPL = unrealizedPL + realizedBase + dividendsBase;
    final returnPct = investedBase.minorUnits == 0
        ? 0.0
        : unrealizedPL.minorUnits / investedBase.minorUnits;

    final dayChangeBase = _dayChange(input.quote, holding.quantity, rate, base);

    return HoldingValuation(
      assetId: holding.assetId,
      institutionId: holding.institutionId,
      assetKind: input.asset.kind,
      quantity: holding.quantity,
      marketValueBase: marketValueBase,
      investedBase: investedBase,
      unrealizedPL: unrealizedPL,
      totalPL: totalPL,
      returnPct: returnPct,
      dayChangeBase: dayChangeBase,
      priceStale: stale,
    );
  }

  /// A foreign holding that can't be priced in base (no FX): every base figure
  /// zeroed and `fxMissing` set, so totals exclude it and the UI can warn.
  HoldingValuation _unvaluable(ValuationInput input, Currency base) {
    return HoldingValuation(
      assetId: input.holding.assetId,
      institutionId: input.holding.institutionId,
      assetKind: input.asset.kind,
      quantity: input.holding.quantity,
      marketValueBase: Money.zero(base),
      investedBase: Money.zero(base),
      unrealizedPL: Money.zero(base),
      totalPL: Money.zero(base),
      returnPct: 0,
      dayChangeBase: Money.zero(base),
      priceStale: true,
      fxMissing: true,
    );
  }

  /// Values the whole portfolio and aggregates allocations.
  PortfolioValuation valuatePortfolio(
    List<ValuationInput> inputs, {
    required DateTime now,
    Currency base = Currency.brl,
    Duration staleThreshold = defaultStaleThreshold,
  }) {
    final valuations = [
      for (final input in inputs)
        valuateHolding(
          input,
          now: now,
          base: base,
          staleThreshold: staleThreshold,
        ),
    ];

    var totalValue = Money.zero(base);
    var totalInvested = Money.zero(base);
    var totalUnrealized = Money.zero(base);
    var totalDay = Money.zero(base);
    final byClass = <AssetKind, Money>{};
    final byInstitution = <String, Money>{};

    for (final v in valuations) {
      // Foreign holdings with no FX rate are excluded from every total (they're
      // still returned in `holdings` so the UI can list them with a warning).
      if (v.fxMissing) continue;
      totalValue += v.marketValueBase;
      totalInvested += v.investedBase;
      totalUnrealized += v.unrealizedPL;
      totalDay += v.dayChangeBase;
      byClass[v.assetKind] =
          (byClass[v.assetKind] ?? Money.zero(base)) + v.marketValueBase;
      byInstitution[v.institutionId] =
          (byInstitution[v.institutionId] ?? Money.zero(base)) +
              v.marketValueBase;
    }

    final totalReturnPct = totalInvested.minorUnits == 0
        ? 0.0
        : totalUnrealized.minorUnits / totalInvested.minorUnits;

    return PortfolioValuation(
      totalValueBase: totalValue,
      totalInvestedBase: totalInvested,
      totalUnrealizedPL: totalUnrealized,
      totalDayChangeBase: totalDay,
      totalReturnPct: totalReturnPct,
      byClass: byClass,
      byInstitution: byInstitution,
      holdings: valuations,
    );
  }

  /// `(marketValueBase, unrealizedPL, stale)` for a holding: from a live quote
  /// if present, else fixed-income accrual, else cost basis (flagged stale).
  (Money, Money, bool) _price(
    ValuationInput input,
    Money investedBase,
    double rate,
    DateTime now,
    Currency base,
    Duration staleThreshold,
  ) {
    final holding = input.holding;
    final quote = input.quote;

    if (quote != null) {
      final marketNative = Money(
        (quote.unitPrice.minorUnits * holding.quantity).round(),
        quote.unitPrice.currency,
      );
      final marketValueBase = _toBase(marketNative, rate, base);
      final stale = now.difference(quote.fetchedAt) > staleThreshold;
      return (marketValueBase, marketValueBase - investedBase, stale);
    }
    if (input.fixedIncome != null) {
      final accruedNative =
          holding.investedCost * _accrualFactor(input.fixedIncome!, now);
      final marketValueBase = _toBase(accruedNative, rate, base);
      return (marketValueBase, marketValueBase - investedBase, false);
    }
    return (investedBase, Money.zero(base), true);
  }

  Money _dayChange(Quote? quote, double quantity, double fx, Currency base) {
    final previousClose = quote?.previousClose;
    if (quote == null || previousClose == null) return Money.zero(base);
    final deltaNative = Money(
      ((quote.unitPrice.minorUnits - previousClose.minorUnits) * quantity)
          .round(),
      quote.unitPrice.currency,
    );
    return _toBase(deltaNative, fx, base);
  }

  Money _toBase(Money amount, double fx, Currency base) {
    if (amount.currency == base) return Money(amount.minorUnits, base);
    return Money((amount.minorUnits * fx).round(), base);
  }

  /// Multiplier applied to the principal to reach current value. See
  /// `docs/specs/valuation.md` §2.
  double _accrualFactor(FixedIncomeTerms terms, DateTime now) {
    return switch (terms.basis) {
      FixedIncomeBasis.cdi || FixedIncomeBasis.selic => _indexedFactor(terms),
      FixedIncomeBasis.prefixed =>
        _prefixedFactor(terms.ratePercent, terms.purchaseDate, now),
      FixedIncomeBasis.ipca => _ipcaFactor(terms, now),
    };
  }

  /// CDI/Selic: compound each daily rate scaled by the contracted percentage.
  /// `110% of CDI` → `∏(1 + dailyCdi * 1.10)`.
  double _indexedFactor(FixedIncomeTerms terms) {
    final multiplier = terms.ratePercent / 100;
    var factor = 1.0;
    for (final point in terms.series) {
      if (point.date.isBefore(terms.purchaseDate)) continue;
      factor *= 1 + (point.rate / 100) * multiplier;
    }
    return factor;
  }

  /// Prefixed: annual rate compounded over business days (252-day convention).
  double _prefixedFactor(double annualRate, DateTime since, DateTime now) {
    final days = _businessDaysBetween(since, now);
    return pow(1 + annualRate / 100, days / 252).toDouble();
  }

  /// IPCA+: accumulated monthly inflation times the spread over business days.
  double _ipcaFactor(FixedIncomeTerms terms, DateTime now) {
    var inflation = 1.0;
    for (final point in terms.series) {
      if (point.date.isBefore(terms.purchaseDate)) continue;
      inflation *= 1 + point.rate / 100;
    }
    final days = _businessDaysBetween(terms.purchaseDate, now);
    final spread = pow(1 + terms.ratePercent / 100, days / 252).toDouble();
    return inflation * spread;
  }

  /// Weekday count in `(from, to]`. Approximation: ignores bank holidays, which
  /// the BCB series already excludes for index-based bonds; only prefixed/IPCA+
  /// spreads are slightly affected.
  int _businessDaysBetween(DateTime from, DateTime to) {
    if (!to.isAfter(from)) return 0;
    var count = 0;
    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (cursor.isBefore(end)) {
      cursor = cursor.add(const Duration(days: 1));
      final weekday = cursor.weekday;
      if (weekday != DateTime.saturday && weekday != DateTime.sunday) count++;
    }
    return count;
  }
}
