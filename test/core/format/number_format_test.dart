import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/format/number_format.dart';

void main() {
  group('formatTrimmedDouble', () {
    test('drops the decimal for a whole value', () {
      expect(formatTrimmedDouble(3), '3');
      expect(formatTrimmedDouble(110), '110');
    });

    test('keeps the decimal for a fractional value', () {
      expect(formatTrimmedDouble(3.5), '3.5');
      expect(formatTrimmedDouble(0.25), '0.25');
    });
  });
}
