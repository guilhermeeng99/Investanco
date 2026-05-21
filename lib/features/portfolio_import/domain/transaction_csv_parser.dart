import 'package:investanco/features/portfolio_import/domain/csv_field_parsers.dart';
import 'package:investanco/features/portfolio_import/domain/transaction_import_models.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// Parses a transactions CSV into [TransactionImportRow]s. Pure: throws a
/// [FormatException] tagged with the offending row. Required columns: `ticker`,
/// `institution`; `quantity`/`price` required for buy/sell, `amount` for
/// dividends. Currency is taken from the referenced asset at import time, not
/// from the file. See `docs/specs/csv_import.md`.
List<TransactionImportRow> parseTransactionsCsv(String csv) {
  final table = readCsvTable(csv);
  final cols = mapCsvHeader(table.first);
  for (final required in const ['ticker', 'institution']) {
    if (!cols.containsKey(required)) {
      throw FormatException('CSV is missing the required "$required" column.');
    }
  }

  final rows = <TransactionImportRow>[];
  var lineNo = 1; // header
  for (final raw in table.skip(1)) {
    lineNo++;
    if (raw.every((c) => c.trim().isEmpty)) continue; // tolerate blank lines
    rows.add(_parseRow(raw, cols, lineNo));
  }
  if (rows.isEmpty) throw const FormatException('CSV has no valid rows.');
  return rows;
}

TransactionImportRow _parseRow(
  List<String> raw,
  Map<String, int> cols,
  int lineNo,
) {
  String cell(String key) {
    final idx = cols[key];
    if (idx == null || idx >= raw.length) return '';
    return raw[idx].trim();
  }

  final ticker = cell('ticker');
  if (ticker.isEmpty) throw FormatException('Row $lineNo: empty ticker.');
  final institution = cell('institution');
  if (institution.isEmpty) {
    throw FormatException('Row $lineNo: empty institution.');
  }

  final operation = parseOperation(cell('operation'), lineNo);
  final dateStr = cell('date');
  final date = dateStr.isEmpty ? csvToday() : parseCsvDate(dateStr, lineNo);
  final fees = optionalCsvNumber(cell('fees'), lineNo, 'fees') ?? 0;
  final notes = cell('notes').isEmpty ? null : cell('notes');

  if (operation == TransactionKind.dividend) {
    final amount = requiredCsvNumber(cell('amount'), lineNo, 'amount');
    return TransactionImportRow(
      ticker: ticker.toUpperCase(),
      institutionName: institution,
      operation: operation,
      quantity: 0,
      unitPriceMajor: 0,
      feesMajor: fees,
      amountMajor: amount,
      date: date,
      notes: notes,
    );
  }

  final quantity = requiredCsvNumber(cell('quantity'), lineNo, 'quantity');
  if (quantity <= 0) {
    throw FormatException('Row $lineNo: quantity must be greater than zero.');
  }
  final price = requiredCsvNumber(cell('price'), lineNo, 'price');
  return TransactionImportRow(
    ticker: ticker.toUpperCase(),
    institutionName: institution,
    operation: operation,
    quantity: quantity,
    unitPriceMajor: price,
    feesMajor: fees,
    date: date,
    notes: notes,
  );
}
