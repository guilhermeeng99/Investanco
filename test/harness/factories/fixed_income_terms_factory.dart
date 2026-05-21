import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';

/// Test factory for [FixedIncomeTerms]. Defaults to 100% of CDI with a single
/// R$10,000 lot bought 2026-05-01 and an empty series. Pass [lots] for the
/// multi-contribution case; otherwise a single lot is built from [purchaseDate]
/// and [principal]. Never hardcode entities in tests.
FixedIncomeTerms fixedIncomeTermsFactory({
  FixedIncomeBasis basis = FixedIncomeBasis.cdi,
  double ratePercent = 100,
  DateTime? purchaseDate,
  Money? principal,
  List<FixedIncomeLot>? lots,
  List<IndexPoint> series = const [],
}) {
  return FixedIncomeTerms(
    basis: basis,
    ratePercent: ratePercent,
    lots: lots ??
        [
          FixedIncomeLot(
            date: purchaseDate ?? DateTime(2026, 5, 1),
            principal: principal ?? const Money(1000000, Currency.brl),
          ),
        ],
    series: series,
  );
}
