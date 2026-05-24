import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// Below this, a residual quantity is rounding noise (fractional crypto/US
/// shares) rather than a real oversell.
const double _qtyEpsilon = 1e-9;

/// Whether the [transactions] of a single (asset, institution) position ever
/// drive the running net quantity below zero when applied oldest-first — i.e. a
/// sell exceeds the quantity held on its date. Buys add, sells subtract,
/// dividends leave quantity untouched.
///
/// Ordering mirrors `HoldingCalculator` (date, then createdAt) with a final
/// buy-before-sell tiebreak, so a same-instant deposit covers its redemption —
/// e.g. bulk-imported fixed-income cash flows that share a timestamp.
///
/// Example:
/// ```dart
/// oversellsTimeline([buy10Jan1, sell4Feb1]); // false
/// oversellsTimeline([sell1]);                 // true — nothing is held
/// ```
bool oversellsTimeline(List<AssetTransaction> transactions) {
  final ordered = [...transactions]..sort(_oldestFirst);
  var quantity = 0.0;
  for (final tx in ordered) {
    switch (tx.kind) {
      case TransactionKind.buy:
        quantity += tx.quantity;
      case TransactionKind.sell:
        quantity -= tx.quantity;
        if (quantity < -_qtyEpsilon) return true;
      case TransactionKind.dividend:
        break;
    }
  }
  return false;
}

int _oldestFirst(AssetTransaction a, AssetTransaction b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  final byCreation = a.createdAt.compareTo(b.createdAt);
  if (byCreation != 0) return byCreation;
  // On an exact tie, settle buys before sells so a deposit covers a same-instant
  // redemption (otherwise the unstable sort could read a false oversell).
  return transactionKindRank(a.kind).compareTo(transactionKindRank(b.kind));
}
