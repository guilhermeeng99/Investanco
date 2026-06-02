import 'package:investanco/features/assets/domain/asset_kind_defaults.dart';
import 'package:investanco/features/portfolio_import/domain/asset_import_models.dart';
import 'package:investanco/features/portfolio_import/domain/csv_field_parsers.dart';

/// Parses an assets CSV into [AssetImportRow]s. Pure: throws a [FormatException]
/// tagged with the offending row on bad input. Required columns: `ticker`,
/// `kind`; `market`/`currency` default from the kind, `name` defaults to the
/// ticker. See `docs/specs/csv_import.md`.
List<AssetImportRow> parseAssetsCsv(String csv) {
  final table = readCsvTable(csv);
  final cols = mapCsvHeader(table.first);
  for (final required in const ['ticker', 'kind', 'institution']) {
    if (!cols.containsKey(required)) {
      throw FormatException('CSV is missing the required "$required" column.');
    }
  }

  final rows = <AssetImportRow>[];
  var lineNo = 1; // header
  for (final raw in table.skip(1)) {
    lineNo++;
    if (raw.every((c) => c.trim().isEmpty)) continue; // tolerate blank lines
    rows.add(_parseRow(raw, cols, lineNo));
  }
  if (rows.isEmpty) throw const FormatException('CSV has no valid rows.');
  return rows;
}

AssetImportRow _parseRow(List<String> raw, Map<String, int> cols, int lineNo) {
  String cell(String key) {
    final idx = cols[key];
    if (idx == null || idx >= raw.length) return '';
    return raw[idx].trim();
  }

  final ticker = cell('ticker');
  if (ticker.isEmpty) throw FormatException('Row $lineNo: empty ticker.');

  final kind = parseAssetKind(cell('kind'), lineNo);
  final (defMarket, defCurrency) = assetKindDefaults(kind);
  final marketStr = cell('market');
  final currencyStr = cell('currency');
  final name = cell('name');
  final institution = cell('institution');
  if (institution.isEmpty) {
    throw FormatException('Row $lineNo: empty institution.');
  }

  return AssetImportRow(
    ticker: ticker.toUpperCase(),
    name: name.isEmpty ? ticker.toUpperCase() : name,
    kind: kind,
    market: marketStr.isEmpty ? defMarket : parseMarket(marketStr, lineNo),
    currency: currencyStr.isEmpty
        ? defCurrency
        : parseCurrency(currencyStr, lineNo),
    institutionName: institution,
  );
}
