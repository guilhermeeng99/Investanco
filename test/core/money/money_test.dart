import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';

void main() {
  group('Money', () {
    test('fromMajor rounds to nearest cent', () {
      expect(Money.fromMajor(10.50, Currency.brl).minorUnits, 1050);
      expect(Money.fromMajor(10.999, Currency.brl).minorUnits, 1100);
    });

    test('addition keeps currency and sums minor units', () {
      const a = Money(1050, Currency.brl);
      const b = Money(200, Currency.brl);
      expect(a + b, const Money(1250, Currency.brl));
    });

    test('subtraction yields the difference', () {
      const a = Money(1050, Currency.brl);
      const b = Money(200, Currency.brl);
      expect((a - b).minorUnits, 850);
    });

    test('multiplication scales and rounds', () {
      expect((const Money(1050, Currency.brl) * 3).minorUnits, 3150);
    });

    test('major returns the decimal value', () {
      expect(const Money(3150, Currency.brl).major, 31.5);
    });

    test('zero is zero', () {
      expect(const Money.zero(Currency.usd).isZero, isTrue);
    });

    test('combining different currencies throws (release-safe guard)', () {
      const brl = Money(100, Currency.brl);
      const usd = Money(100, Currency.usd);
      expect(() => brl + usd, throwsArgumentError);
      expect(() => brl - usd, throwsArgumentError);
    });
  });
}
