import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';

void main() {
  group('formatCurrency', () {
    test(r'formats BRL with pt_BR grouping and the R$ symbol', () {
      final text = formatCurrency(Money.fromMajor(1234.5, Currency.brl));
      expect(text, contains('1.234,50'));
      expect(text, contains(r'R$'));
    });

    test(r'formats USD with en_US grouping and the $ symbol', () {
      final text = formatCurrency(Money.fromMajor(1234.5, Currency.usd));
      expect(text, contains('1,234.50'));
      expect(text, contains(r'$'));
    });
  });

  group('formatPercent', () {
    test('prefixes a positive ratio with +', () {
      final text = formatPercent(0.1234);
      expect(text, startsWith('+'));
      expect(text, contains('12,34'));
    });

    test('keeps a negative ratio without a plus', () {
      final text = formatPercent(-0.05);
      expect(text.startsWith('+'), isFalse);
      expect(text, contains('-'));
    });

    test('zero has no sign prefix', () {
      expect(formatPercent(0).startsWith('+'), isFalse);
    });
  });
}
