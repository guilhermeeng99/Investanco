import 'package:equatable/equatable.dart';
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

/// Everything needed to accrue one fixed-income holding to its current value.
///
/// [ratePercent] meaning depends on [basis]:
/// - `cdi`/`selic`: percent **of** the index (110 → 110% of CDI);
/// - `prefixed`: the annual rate itself (12 → 12% a.a.);
/// - `ipca`: the annual spread over inflation (6 → IPCA + 6% a.a.).
///
/// [series] is the index observations since [purchaseDate] (daily for CDI/Selic,
/// monthly for IPCA); it is empty for `prefixed`.
class FixedIncomeTerms extends Equatable {
  /// Creates the terms.
  const FixedIncomeTerms({
    required this.basis,
    required this.ratePercent,
    required this.purchaseDate,
    this.series = const [],
  });

  /// Accrual basis.
  final FixedIncomeBasis basis;

  /// Contracted rate; meaning varies by [basis] (see class doc).
  final double ratePercent;

  /// When accrual starts (earliest buy of the holding).
  final DateTime purchaseDate;

  /// Index observations since [purchaseDate]; empty for `prefixed`.
  final List<IndexPoint> series;

  @override
  List<Object?> get props => [basis, ratePercent, purchaseDate, series];
}
