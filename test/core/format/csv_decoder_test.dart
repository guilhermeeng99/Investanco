import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/format/csv_decoder.dart';

void main() {
  group('decodeCsvBytes', () {
    test('decodes UTF-8 with accents', () {
      final bytes = utf8.encode('ticker,instituição\nSOXX,Avenue');
      expect(decodeCsvBytes(bytes), 'ticker,instituição\nSOXX,Avenue');
    });

    test('falls back to Latin-1 for non-UTF-8 bytes (BR Excel exports)', () {
      // These bytes are valid Latin-1/Windows-1252 but invalid UTF-8; strict
      // UTF-8 decoding would throw, so the decoder must fall back.
      final bytes = latin1.encode('Instituição,Corretora');
      expect(decodeCsvBytes(bytes), 'Instituição,Corretora');
    });

    test('strips a leading UTF-8 BOM', () {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('ticker,kind')];
      expect(decodeCsvBytes(bytes), 'ticker,kind');
    });

    test('passes plain ASCII through unchanged', () {
      expect(decodeCsvBytes(utf8.encode('a,b,c')), 'a,b,c');
    });
  });
}
