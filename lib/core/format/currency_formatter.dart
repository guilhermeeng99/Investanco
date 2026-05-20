import 'package:intl/intl.dart';
import 'package:investanco/core/money/money.dart';

/// Formats [Money] using locale-aware currency rules.
///
/// Example: `formatCurrency(Money.fromMajor(1234.5, Currency.brl)) // R$1.234,50`
String formatCurrency(Money money) {
  final format = NumberFormat.currency(
    locale: money.currency.locale,
    symbol: money.currency.symbol,
  );
  return format.format(money.major);
}

/// Formats a ratio as a signed percentage (e.g. 0.1234 → "+12,34%").
String formatPercent(double ratio, {String locale = 'pt_BR'}) {
  final format = NumberFormat.decimalPercentPattern(
    locale: locale,
    decimalDigits: 2,
  );
  final sign = ratio > 0 ? '+' : '';
  return '$sign${format.format(ratio)}';
}
