import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/portfolio_import/domain/csv_field_parsers.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

void main() {
  group('parseCsvNumber', () {
    test('reads BR grouping (1.234,56 → 1234.56)', () {
      expect(parseCsvNumber('1.234,56'), 1234.56);
    });

    test('reads EN grouping (1,234.56 → 1234.56)', () {
      expect(parseCsvNumber('1,234.56'), 1234.56);
    });

    test('treats a lone comma as the decimal separator', () {
      expect(parseCsvNumber('10,50'), 10.5);
    });

    test('treats a lone dot as the decimal separator (1.000 → 1.0)', () {
      expect(parseCsvNumber('1.000'), 1.0);
    });

    test('returns the absolute value (sign is carried by the operation)', () {
      expect(parseCsvNumber('-5'), 5.0);
    });

    test('strips surrounding quotes', () {
      expect(parseCsvNumber('"1.234,56"'), 1234.56);
    });

    test('returns null for blank or unparsable input', () {
      expect(parseCsvNumber(''), isNull);
      expect(parseCsvNumber('abc'), isNull);
    });
  });

  group('parseCsvDate', () {
    test('accepts DD/MM/YYYY', () {
      expect(parseCsvDate('09/05/2026', 2), DateTime(2026, 5, 9));
    });

    test('accepts YYYY-MM-DD', () {
      expect(parseCsvDate('2026-05-09', 2), DateTime(2026, 5, 9));
    });

    test('throws on an out-of-range month', () {
      expect(() => parseCsvDate('09/13/2026', 2), throwsFormatException);
    });

    test('throws on garbage', () {
      expect(() => parseCsvDate('not-a-date', 2), throwsFormatException);
    });
  });

  group('parseAssetKind', () {
    test('reads the enum name', () {
      expect(parseAssetKind('stockBr', 2), AssetKind.stockBr);
    });

    test('reads friendly PT/EN labels, accent/case-insensitive', () {
      expect(parseAssetKind('Renda Fixa', 2), AssetKind.fixedIncome);
      expect(parseAssetKind('ETF (EUA)', 2), AssetKind.etfUs);
      expect(parseAssetKind('cripto', 2), AssetKind.crypto);
    });

    test('throws on empty or unknown', () {
      expect(() => parseAssetKind('', 2), throwsFormatException);
      expect(() => parseAssetKind('widgets', 2), throwsFormatException);
    });
  });

  group('parseMarket / parseCurrency', () {
    test('resolves market synonyms', () {
      expect(parseMarket('Brasil', 2), Market.br);
      expect(parseMarket('EUA', 2), Market.us);
      expect(parseMarket('world', 2), Market.global);
      expect(() => parseMarket('moon', 2), throwsFormatException);
    });

    test('resolves currency synonyms', () {
      expect(parseCurrency('Reais', 2), Currency.brl);
      expect(parseCurrency('Dólar', 2), Currency.usd);
      expect(() => parseCurrency('btc', 2), throwsFormatException);
    });
  });

  group('parseOperation', () {
    test('defaults to buy when blank', () {
      expect(parseOperation('', 2), TransactionKind.buy);
    });

    test('resolves PT/EN synonyms', () {
      expect(parseOperation('Venda', 2), TransactionKind.sell);
      expect(parseOperation('Proventos', 2), TransactionKind.dividend);
      expect(parseOperation('C', 2), TransactionKind.buy);
    });

    test('throws on an unknown operation', () {
      expect(() => parseOperation('transfer', 2), throwsFormatException);
    });
  });

  group('mapCsvHeader / normalizeCsvToken', () {
    test('maps reordered, accented headers to logical keys', () {
      final cols = mapCsvHeader(['Preço Médio', 'Ticker', 'Quantidade']);
      expect(cols['price'], 0);
      expect(cols['ticker'], 1);
      expect(cols['quantity'], 2);
    });

    test('ignores unrecognized columns', () {
      final cols = mapCsvHeader(['Ticker', 'Random Column']);
      expect(cols['ticker'], 0);
      expect(cols.containsKey('random'), isFalse);
    });

    test('strips accents and non-alphanumerics', () {
      expect(normalizeCsvToken('ETF (EUA)'), 'etfeua');
      expect(normalizeCsvToken('Preço médio'), 'precomedio');
    });
  });

  group('requiredCsvNumber / optionalCsvNumber', () {
    test('requiredCsvNumber throws when missing or invalid', () {
      expect(() => requiredCsvNumber('', 2, 'price'), throwsFormatException);
      expect(() => requiredCsvNumber('x', 2, 'price'), throwsFormatException);
      expect(requiredCsvNumber('10,5', 2, 'price'), 10.5);
    });

    test('optionalCsvNumber is null when blank but throws when invalid', () {
      expect(optionalCsvNumber('', 2, 'fees'), isNull);
      expect(optionalCsvNumber('1,5', 2, 'fees'), 1.5);
      expect(() => optionalCsvNumber('x', 2, 'fees'), throwsFormatException);
    });
  });

  group('readCsvTable', () {
    test('returns the table when it has a header plus data', () {
      final table = readCsvTable('ticker,kind\nPETR4,stockBr');
      expect(table.length, 2);
    });

    test('throws when there are no data rows', () {
      expect(() => readCsvTable('ticker,kind'), throwsFormatException);
    });
  });
}
