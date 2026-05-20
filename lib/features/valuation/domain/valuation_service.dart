import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/holdings/domain/entities/holding.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
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
  });

  /// The position.
  final Holding holding;

  /// Its asset (for currency/class).
  final Asset asset;

  /// Latest quote, or null when unavailable.
  final Quote? quote;

  /// Multiplier converting the asset's currency to the base currency
  /// (1.0 when already in base).
  final double fxToBase;
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
    final quote = input.quote;
    final fx = input.fxToBase;

    final investedBase = _toBase(holding.investedCost, fx, base);

    final Money marketValueBase;
    final Money unrealizedPL;
    final bool stale;
    if (quote == null) {
      marketValueBase = investedBase;
      unrealizedPL = Money.zero(base);
      stale = true;
    } else {
      final marketNative = Money(
        (quote.unitPrice.minorUnits * holding.quantity).round(),
        quote.unitPrice.currency,
      );
      marketValueBase = _toBase(marketNative, fx, base);
      unrealizedPL = marketValueBase - investedBase;
      stale = now.difference(quote.fetchedAt) > staleThreshold;
    }

    final realizedBase = _toBase(holding.realizedPL, fx, base);
    final dividendsBase = _toBase(holding.dividends, fx, base);
    final totalPL = unrealizedPL + realizedBase + dividendsBase;
    final returnPct = investedBase.minorUnits == 0
        ? 0.0
        : unrealizedPL.minorUnits / investedBase.minorUnits;

    final dayChangeBase = _dayChange(quote, holding.quantity, fx, base);

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
}
