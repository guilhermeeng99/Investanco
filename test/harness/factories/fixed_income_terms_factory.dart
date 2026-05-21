import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';

/// Test factory for [FixedIncomeTerms]. Defaults to 100% of CDI with a single
/// R$10,000 deposit on 2026-05-01 and an empty series. Pass [cashFlows] for the
/// multi-movement case (deposits and redemptions); otherwise a single deposit is
/// built from [purchaseDate] and [principal]. Never hardcode entities in tests.
FixedIncomeTerms fixedIncomeTermsFactory({
  FixedIncomeBasis basis = FixedIncomeBasis.cdi,
  double ratePercent = 100,
  DateTime? purchaseDate,
  Money? principal,
  List<FixedIncomeCashFlow>? cashFlows,
  List<IndexPoint> series = const [],
}) {
  return FixedIncomeTerms(
    basis: basis,
    ratePercent: ratePercent,
    cashFlows: cashFlows ??
        [
          FixedIncomeCashFlow(
            date: purchaseDate ?? DateTime(2026, 5, 1),
            amount: principal ?? const Money(1000000, Currency.brl),
          ),
        ],
    series: series,
  );
}
