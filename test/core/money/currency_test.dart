import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';

void main() {
  test('BRL carries its ISO code, symbol and locale', () {
    expect(Currency.brl.code, 'BRL');
    expect(Currency.brl.symbol, r'R$');
    expect(Currency.brl.locale, 'pt_BR');
  });

  test('USD carries its ISO code, symbol and locale', () {
    expect(Currency.usd.code, 'USD');
    expect(Currency.usd.symbol, r'$');
    expect(Currency.usd.locale, 'en_US');
  });

  test('exposes exactly the supported currencies', () {
    expect(Currency.values, [Currency.brl, Currency.usd]);
  });
}
