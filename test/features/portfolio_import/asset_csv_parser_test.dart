import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/portfolio_import/domain/asset_csv_parser.dart';

void main() {
  group('parseAssetsCsv', () {
    const header = 'ticker,kind,institution';

    test('parses a minimal row, defaulting name/market/currency', () {
      final row = parseAssetsCsv('$header\nsoxx,etfeua,Avenue').single;

      expect(row.ticker, 'SOXX'); // uppercased
      expect(row.name, 'SOXX'); // name defaults to the ticker
      expect(row.kind, AssetKind.etfUs);
      expect(row.market, Market.us); // from the kind defaults
      expect(row.currency, Currency.usd);
      expect(row.institutionName, 'Avenue');
    });

    test('defaults crypto to Global market and BRL currency', () {
      final row = parseAssetsCsv('$header\nBTC,crypto,Nubank').single;

      expect(row.kind, AssetKind.crypto);
      expect(row.market, Market.global);
      expect(row.currency, Currency.brl);
    });

    test('honors explicit name, market and currency columns', () {
      final row = parseAssetsCsv(
        'ticker,name,kind,market,currency,institution\n'
        'AAPL,Apple Inc,etfeua,us,usd,Avenue',
      ).single;

      expect(row.name, 'Apple Inc');
      expect(row.market, Market.us);
      expect(row.currency, Currency.usd);
    });

    test('resolves accented Portuguese header synonyms', () {
      final row = parseAssetsCsv(
        'símbolo,tipo,instituição\nPETR4,ação br,Nubank',
      ).single;

      expect(row.ticker, 'PETR4');
      expect(row.kind, AssetKind.stockBr);
      expect(row.institutionName, 'Nubank');
    });

    test('tolerates blank lines between rows', () {
      final rows = parseAssetsCsv('$header\nBTC,crypto,Nubank\n\nETH,crypto,Nubank');
      expect(rows, hasLength(2));
    });

    test('throws when a required column is missing', () {
      expect(
        () => parseAssetsCsv('ticker,kind\nBTC,crypto'),
        throwsFormatException,
      );
    });

    test('throws when the file has a header but no data rows', () {
      expect(() => parseAssetsCsv(header), throwsFormatException);
    });

    test('throws on an empty ticker', () {
      expect(
        () => parseAssetsCsv('$header\n,crypto,Nubank'),
        throwsFormatException,
      );
    });

    test('throws on an empty institution', () {
      expect(
        () => parseAssetsCsv('$header\nBTC,crypto,'),
        throwsFormatException,
      );
    });

    test('throws on an unknown kind', () {
      expect(
        () => parseAssetsCsv('$header\nBTC,banana,Nubank'),
        throwsFormatException,
      );
    });
  });
}
