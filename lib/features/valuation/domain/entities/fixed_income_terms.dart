import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';

/// How a fixed-income position accrues. Drives which formula values it.
enum FixedIncomeBasis {
  /// Percentage of the CDI daily rate (e.g. 110% of CDI).
  cdi,

  /// Percentage of the Selic daily rate.
  selic,

  /// Fixed annual rate, compounded over business days (e.g. 12% a.a.).
  prefixed,

  /// IPCA monthly inflation plus a fixed annual spread (e.g. IPCA + 6% a.a.).
  ipca,
}

/// Maps an accrual basis to the BCB index whose series it needs.
extension FixedIncomeBasisIndex on FixedIncomeBasis {
  /// The economic index to fetch, or null for `prefixed` (needs no series).
  EconomicIndex? get economicIndex => switch (this) {
        FixedIncomeBasis.cdi => EconomicIndex.cdi,
        FixedIncomeBasis.selic => EconomicIndex.selic,
        FixedIncomeBasis.ipca => EconomicIndex.ipca,
        FixedIncomeBasis.prefixed => null,
      };
}

/// One contribution (deposit) into a fixed-income position: how much principal
/// went in and when. Each lot accrues from its own [date], so recurring deposits
/// into a CDB/RDB/caixinha are valued correctly instead of all accruing from the
/// first deposit (which over-counts later money).
class FixedIncomeLot extends Equatable {
  /// Creates a lot.
  const FixedIncomeLot({required this.date, required this.principal});

  /// When this contribution was made — accrual start for this lot.
  final DateTime date;

  /// Principal contributed (native currency).
  final Money principal;

  @override
  List<Object?> get props => [date, principal];
}

/// Everything needed to accrue one fixed-income holding to its current value.
///
/// [ratePercent] meaning depends on [basis]:
/// - `cdi`/`selic`: percent **of** the index (110 → 110% of CDI);
/// - `prefixed`: the annual rate itself (12 → 12% a.a.);
/// - `ipca`: the annual spread over inflation (6 → IPCA + 6% a.a.).
///
/// The position is a list of [lots] (one per contribution); each accrues from
/// its own date, and they sum to the holding's invested cost. [series] is the
/// index observations since the earliest lot (daily for CDI/Selic, monthly for
/// IPCA); it is empty for `prefixed`.
class FixedIncomeTerms extends Equatable {
  /// Creates the terms.
  const FixedIncomeTerms({
    required this.basis,
    required this.ratePercent,
    required this.lots,
    this.series = const [],
  });

  /// Accrual basis.
  final FixedIncomeBasis basis;

  /// Contracted rate; meaning varies by [basis] (see class doc).
  final double ratePercent;

  /// Contributions making up the position; each accrues from its own date.
  final List<FixedIncomeLot> lots;

  /// Index observations since the earliest lot; empty for `prefixed`.
  final List<IndexPoint> series;

  /// Earliest contribution date, or null when there are no lots.
  DateTime? get earliestDate => lots.isEmpty
      ? null
      : lots.map((l) => l.date).reduce((a, b) => a.isBefore(b) ? a : b);

  @override
  List<Object?> get props => [basis, ratePercent, lots, series];
}
