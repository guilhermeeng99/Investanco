import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/format/csv_parser.dart';

void main() {
  group('parseCsv', () {
    test('splits simple rows and cells', () {
      expect(
        parseCsv('a,b,c\n1,2,3'),
        [
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ],
      );
    });

    test('keeps commas inside quoted fields', () {
      expect(
        parseCsv('name,note\n"Vanguard, Inc.",ok'),
        [
          ['name', 'note'],
          ['Vanguard, Inc.', 'ok'],
        ],
      );
    });

    test('unescapes doubled quotes inside a quoted field', () {
      expect(
        parseCsv('a\n"she said ""hi"""'),
        [
          ['a'],
          ['she said "hi"'],
        ],
      );
    });

    test('handles CRLF line endings', () {
      expect(
        parseCsv('a,b\r\n1,2\r\n'),
        [
          ['a', 'b'],
          ['1', '2'],
        ],
      );
    });

    test('drops blank lines and a trailing newline', () {
      expect(
        parseCsv('a\n\n1\n'),
        [
          ['a'],
          ['1'],
        ],
      );
    });

    test('returns empty list for empty input', () {
      expect(parseCsv(''), isEmpty);
    });
  });
}
