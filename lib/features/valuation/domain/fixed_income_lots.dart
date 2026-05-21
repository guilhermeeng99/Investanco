import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/valuation/domain/entities/fixed_income_terms.dart';

/// Splits a fixed-income holding's net [invested] cost across its [buys],
/// weighted by each buy's gross amount (`unitPrice × quantity + fees`), so every
/// contribution accrues from its own date.
///
/// Why distribute the *net* invested instead of summing raw buy amounts: sells
/// (partial redemptions) are already netted into [invested] via the holding's
/// weighted-average cost, so scaling the buys to it keeps the lots consistent
/// with the rest of the valuation. With no sells the lots equal the buy amounts
/// exactly. The rounding remainder lands on the last (latest) lot so the lots
/// sum back to [invested] to the cent.
///
/// Returns lots ordered oldest-first; empty when there is nothing to accrue.
List<FixedIncomeLot> buildFixedIncomeLots(
  Money invested,
  List<AssetTransaction> buys,
) {
  if (invested.minorUnits <= 0 || buys.isEmpty) return const [];

  final sorted = [...buys]..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
    });
  final weights = [
    for (final b in sorted)
      b.unitPrice.minorUnits * b.quantity + b.fees.minorUnits,
  ];
  final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);
  if (totalWeight <= 0) return const [];

  final currency = invested.currency;
  final lots = <FixedIncomeLot>[];
  var assigned = 0;
  for (var i = 0; i < sorted.length; i++) {
    final isLast = i == sorted.length - 1;
    final minor = isLast
        ? invested.minorUnits - assigned
        : (invested.minorUnits * weights[i] / totalWeight).round();
    assigned += minor;
    lots.add(
      FixedIncomeLot(date: sorted[i].date, principal: Money(minor, currency)),
    );
  }
  return lots;
}
