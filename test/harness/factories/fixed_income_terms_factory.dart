import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';

/// Test factory for [FixedIncomeTerms]. Defaults to 100% of CDI bought
/// 2026-05-01 with an empty series. Never hardcode entities in tests.
FixedIncomeTerms fixedIncomeTermsFactory({
  FixedIncomeBasis basis = FixedIncomeBasis.cdi,
  double ratePercent = 100,
  DateTime? purchaseDate,
  List<IndexPoint> series = const [],
}) {
  return FixedIncomeTerms(
    basis: basis,
    ratePercent: ratePercent,
    purchaseDate: purchaseDate ?? DateTime(2026, 5, 1),
    series: series,
  );
}
