import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/valuation/domain/entities/holding_valuation.dart';

/// The whole portfolio, consolidated to the base currency.
class PortfolioValuation extends Equatable {
  /// Creates a portfolio valuation.
  const PortfolioValuation({
    required this.totalValueBase,
    required this.totalInvestedBase,
    required this.totalUnrealizedPL,
    required this.totalDayChangeBase,
    required this.totalReturnPct,
    required this.byClass,
    required this.byInstitution,
    required this.holdings,
  });

  /// An empty portfolio in [base] currency.
  factory PortfolioValuation.empty([Currency base = Currency.brl]) {
    return PortfolioValuation(
      totalValueBase: Money.zero(base),
      totalInvestedBase: Money.zero(base),
      totalUnrealizedPL: Money.zero(base),
      totalDayChangeBase: Money.zero(base),
      totalReturnPct: 0,
      byClass: const {},
      byInstitution: const {},
      holdings: const [],
    );
  }

  /// Total current value.
  final Money totalValueBase;

  /// Total cost basis.
  final Money totalInvestedBase;

  /// Total unrealized P/L.
  final Money totalUnrealizedPL;

  /// Total day change.
  final Money totalDayChangeBase;

  /// Overall unrealized return ratio.
  final double totalReturnPct;

  /// Value allocation by asset class.
  final Map<AssetKind, Money> byClass;

  /// Value allocation by institution id.
  final Map<String, Money> byInstitution;

  /// Per-holding valuations.
  final List<HoldingValuation> holdings;

  @override
  List<Object?> get props => [
        totalValueBase,
        totalInvestedBase,
        totalUnrealizedPL,
        totalDayChangeBase,
        totalReturnPct,
        byClass,
        byInstitution,
        holdings,
      ];
}
