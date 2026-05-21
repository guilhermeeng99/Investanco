import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/format/money_input.dart';

void main() {
  test('parses a comma decimal separator', () {
    expect(parseMajor('10,50'), 10.5);
  });

  test('parses a dot decimal separator', () {
    expect(parseMajor('10.50'), 10.5);
  });

  test('trims surrounding whitespace', () {
    expect(parseMajor('  10  '), 10);
  });

  test('returns null for non-numeric input', () {
    expect(parseMajor('abc'), isNull);
  });

  test('returns null for empty input', () {
    expect(parseMajor(''), isNull);
  });
}
