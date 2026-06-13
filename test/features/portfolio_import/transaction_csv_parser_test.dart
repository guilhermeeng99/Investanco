import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_csv_parser.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

void main() {
  group('parseTransactionsCsv', () {
    const header = 'ticker,institution,operation,quantity,price';

    test('parses a buy, uppercasing the ticker', () {
      final row = parseTransactionsCsv('$header\nsoxx,Avenue,buy,2,100').single;

      expect(row.ticker, 'SOXX');
      expect(row.institutionName, 'Avenue');
      expect(row.operation, TransactionKind.buy);
      expect(row.quantity, 2);
      expect(row.unitPriceMajor, 100);
      expect(row.feesMajor, 0); // optional, defaults to 0
    });

    test('defaults operation to buy and date to today', () {
      final row = parseTransactionsCsv(
        'ticker,institution,quantity,price\nSOXX,Avenue,2,100',
      ).single;

      expect(row.operation, TransactionKind.buy);
      final now = DateTime.now();
      expect(row.date, DateTime(now.year, now.month, now.day));
    });

    test('parses a dividend with amount and zero quantity', () {
      final row = parseTransactionsCsv(
        'ticker,institution,operation,amount\nSOXX,Avenue,dividend,15.5',
      ).single;

      expect(row.operation, TransactionKind.dividend);
      expect(row.quantity, 0);
      expect(row.unitPriceMajor, 0);
      expect(row.amountMajor, 15.5);
    });

    test('parses BR-grouped numbers (1.234,56) for price', () {
      final row = parseTransactionsCsv(
        '$header\nPETR4,Nubank,buy,10,"1.234,56"',
      ).single;

      expect(row.unitPriceMajor, closeTo(1234.56, 1e-9));
    });

    test('parses an optional fees column', () {
      final row = parseTransactionsCsv(
        '$header,fees\nSOXX,Avenue,buy,2,100,1.25',
      ).single;

      expect(row.feesMajor, closeTo(1.25, 1e-9));
    });

    test('accepts DD/MM/YYYY and YYYY-MM-DD dates', () {
      final slash = parseTransactionsCsv(
        '$header,date\nSOXX,Avenue,buy,2,100,13/06/2026',
      ).single;
      final dash = parseTransactionsCsv(
        '$header,date\nSOXX,Avenue,buy,2,100,2026-06-13',
      ).single;

      expect(slash.date, DateTime(2026, 6, 13));
      expect(dash.date, DateTime(2026, 6, 13));
    });

    test('keeps an optional notes column', () {
      final row = parseTransactionsCsv(
        '$header,notes\nSOXX,Avenue,buy,2,100,first buy',
      ).single;

      expect(row.notes, 'first buy');
    });

    test('tolerates blank lines between rows', () {
      final rows = parseTransactionsCsv(
        '$header\nSOXX,Avenue,buy,2,100\n\nAAPL,Avenue,buy,1,50',
      );
      expect(rows, hasLength(2));
    });

    test('throws when a required column is missing', () {
      expect(
        () => parseTransactionsCsv('ticker,quantity,price\nSOXX,2,100'),
        throwsFormatException,
      );
    });

    test('throws when the file has a header but no data rows', () {
      expect(() => parseTransactionsCsv(header), throwsFormatException);
    });

    test('throws on a non-positive quantity', () {
      expect(
        () => parseTransactionsCsv('$header\nSOXX,Avenue,buy,0,100'),
        throwsFormatException,
      );
    });

    test('throws when a dividend has no amount', () {
      expect(
        () => parseTransactionsCsv(
          'ticker,institution,operation\nSOXX,Avenue,dividend',
        ),
        throwsFormatException,
      );
    });

    test('throws on an empty ticker', () {
      expect(
        () => parseTransactionsCsv('$header\n,Avenue,buy,2,100'),
        throwsFormatException,
      );
    });

    test('throws on an empty institution', () {
      expect(
        () => parseTransactionsCsv('$header\nSOXX,,buy,2,100'),
        throwsFormatException,
      );
    });

    test('throws on an unknown operation', () {
      expect(
        () => parseTransactionsCsv('$header\nSOXX,Avenue,gift,2,100'),
        throwsFormatException,
      );
    });
  });
}
