import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/portfolio_import/domain/csv_validation_failure.dart';

void main() {
  group('CsvValidationFailure.fromMessage', () {
    test('lifts a leading "Row N:" tag into line', () {
      final failure = CsvValidationFailure.fromMessage('Row 3: missing ticker');

      expect(failure.line, 3);
      expect(failure.message, 'Row 3: missing ticker');
    });

    test('a file-level message (no row tag) leaves line null', () {
      final failure =
          CsvValidationFailure.fromMessage('Missing required column: ticker');

      expect(failure.line, isNull);
    });

    test('matches the first row number when several appear', () {
      expect(
        CsvValidationFailure.fromMessage('Row 7: bad reference to Row 9').line,
        7,
      );
    });

    test('is a ValidationFailure so the presentation layer localizes it', () {
      expect(
        CsvValidationFailure.fromMessage('Row 1: x'),
        isA<ValidationFailure>(),
      );
    });

    test('line participates in equality (Equatable props)', () {
      expect(
        CsvValidationFailure.fromMessage('Row 2: a'),
        equals(const CsvValidationFailure('Row 2: a', line: 2)),
      );
      expect(
        CsvValidationFailure.fromMessage('Row 2: a'),
        isNot(const CsvValidationFailure('Row 2: a')),
      );
    });
  });
}
