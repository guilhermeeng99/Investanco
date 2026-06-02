import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/money.dart';

/// Whether a rebalance step adds to (buy) or trims from (sell) a class.
enum RebalanceDirection {
  /// Class is under its target — contribute.
  buy,

  /// Class is over its target — redeem.
  sell,
}

/// One step of the rebalancing plan (per root class, independent).
class RebalanceAction extends Equatable {
  /// Creates an action.
  const RebalanceAction({
    required this.classId,
    required this.className,
    required this.direction,
    required this.amount,
  });

  /// Root class id.
  final String classId;

  /// Root class display name.
  final String className;

  /// Buy (under target) or sell (over target).
  final RebalanceDirection direction;

  /// Absolute amount to move to reach the target (always > 0).
  final Money amount;

  @override
  List<Object?> get props => [classId, className, direction, amount];
}

/// A subclass row within a class detail view.
class InvestmentSubclassSlice extends Equatable {
  /// Creates a subclass slice.
  const InvestmentSubclassSlice({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.percentOfClass,
    required this.percentOfTotal,
    required this.targetPercent,
    required this.suggestedValue,
    required this.suggestedDelta,
    required this.suggestedDeltaNative,
  });

  /// Subclass id.
  final String id;

  /// Subclass name.
  final String name;

  /// Current market value (base currency).
  final Money currentValue;

  /// Share of the parent class (`[0, 1]`).
  final double percentOfClass;

  /// Share of the whole portfolio (`[0, 1]`).
  final double percentOfTotal;

  /// Target share of the parent class (`[0, 100]`).
  final double targetPercent;

  /// Ideal value = parent target value × this subclass's target fraction.
  final Money suggestedValue;

  /// `suggestedValue − currentValue` (+ = aporte, − = reduzir).
  final Money suggestedDelta;

  /// Same suggested delta in the asset's native currency, when different from
  /// the base currency and derivable from the current valuation's FX ratio.
  final Money? suggestedDeltaNative;

  @override
  List<Object?> get props => [
    id,
    name,
    currentValue,
    percentOfClass,
    percentOfTotal,
    targetPercent,
    suggestedValue,
    suggestedDelta,
    suggestedDeltaNative,
  ];
}

/// A root class row in the allocation overview.
class InvestmentClassSlice extends Equatable {
  /// Creates a class slice.
  const InvestmentClassSlice({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.currentValue,
    required this.currentPercent,
    required this.targetPercent,
    required this.targetValue,
    required this.deltaValue,
    required this.subclasses,
  });

  /// Root class id.
  final String id;

  /// Root class name.
  final String name;

  /// Icon key.
  final String iconKey;

  /// ARGB color.
  final int colorValue;

  /// Current market value (own assets + all subclasses).
  final Money currentValue;

  /// Share of the whole portfolio (`[0, 1]`).
  final double currentPercent;

  /// Target share of the whole portfolio (`[0, 100]`).
  final double targetPercent;

  /// Target value = total × target fraction.
  final Money targetValue;

  /// `targetValue − currentValue` (+ = under → buy, − = over → sell).
  final Money deltaValue;

  /// Subclass rows (oldest first).
  final List<InvestmentSubclassSlice> subclasses;

  /// Whether the class is below its target (should receive).
  bool get isUnderTarget => deltaValue.minorUnits > 0;

  /// Whether the class is above its target (should be trimmed).
  bool get isOverTarget => deltaValue.minorUnits < 0;

  @override
  List<Object?> get props => [
    id,
    name,
    iconKey,
    colorValue,
    currentValue,
    currentPercent,
    targetPercent,
    targetValue,
    deltaValue,
    subclasses,
  ];
}

/// The full computed allocation snapshot the UI binds to. See
/// `docs/specs/allocation.md`.
class InvestmentOverview extends Equatable {
  /// Creates an overview.
  const InvestmentOverview({
    required this.total,
    required this.allocated,
    required this.pending,
    required this.classes,
    required this.rebalanceActions,
    required this.targetSumPercent,
  });

  /// An empty overview where every money figure is [zero] (base currency).
  factory InvestmentOverview.empty(Money zero) => InvestmentOverview(
    total: zero,
    allocated: zero,
    pending: zero,
    classes: const [],
    rebalanceActions: const [],
    targetSumPercent: 0,
  );

  /// Total market value of the portfolio (base currency).
  final Money total;

  /// Value with a resolvable class assignment.
  final Money allocated;

  /// Value with no class assignment (`total − allocated`).
  final Money pending;

  /// Root class slices (biggest first).
  final List<InvestmentClassSlice> classes;

  /// Per-class rebalancing steps (biggest gap first).
  final List<RebalanceAction> rebalanceActions;

  /// Sum of root target percentages (should be 100).
  final double targetSumPercent;

  /// Whether there is any value to allocate.
  bool get hasInvestments => total.minorUnits > 0;

  /// Whether some value is unassigned.
  bool get hasPending => pending.minorUnits > 0;

  /// Whether root targets sum to ~100%.
  bool get targetsBalanced => (targetSumPercent - 100).abs() <= 0.1;

  @override
  List<Object?> get props => [
    total,
    allocated,
    pending,
    classes,
    rebalanceActions,
    targetSumPercent,
  ];
}
