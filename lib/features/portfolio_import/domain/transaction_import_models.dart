import 'package:equatable/equatable.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// One parsed, not-yet-persisted transaction CSV row. References an asset by
/// [ticker] (which must already exist) and an institution by name (created if
/// missing). Money fields are in major units of the asset's currency. See
/// `docs/specs/csv_import.md`.
class TransactionImportRow extends Equatable {
  /// Creates a row.
  const TransactionImportRow({
    required this.ticker,
    required this.institutionName,
    required this.operation,
    required this.quantity,
    required this.unitPriceMajor,
    required this.feesMajor,
    required this.date,
    this.amountMajor,
    this.notes,
  });

  /// Asset symbol (uppercased) — must match an existing asset.
  final String ticker;

  /// Custodian name; matched case-insensitively, created if missing.
  final String institutionName;

  /// buy / sell / dividend.
  final TransactionKind operation;

  /// Units (fractional allowed). 0 for dividends.
  final double quantity;

  /// Unit price in major units. 0 for dividends.
  final double unitPriceMajor;

  /// Fees in major units.
  final double feesMajor;

  /// Transaction date.
  final DateTime date;

  /// Dividend total in major units; null for buy/sell.
  final double? amountMajor;

  /// Optional note.
  final String? notes;

  @override
  List<Object?> get props => [
    ticker,
    institutionName,
    operation,
    quantity,
    unitPriceMajor,
    feesMajor,
    date,
    amountMajor,
    notes,
  ];
}

/// A preview row: the parsed [row] plus whether its asset already exists and
/// whether its institution would be created.
class TransactionImportPreviewRow extends Equatable {
  /// Creates a preview row.
  const TransactionImportPreviewRow({
    required this.row,
    required this.assetExists,
    required this.institutionIsNew,
    required this.assetHasInstitution,
    required this.institutionMatchesAsset,
  });

  /// The parsed row.
  final TransactionImportRow row;

  /// True when an asset with this ticker exists (import requires it).
  final bool assetExists;

  /// True when no institution with this name exists yet (created on import).
  final bool institutionIsNew;

  /// True when the referenced asset has a resolvable institution link.
  final bool assetHasInstitution;

  /// True when the CSV institution matches the asset's registered institution.
  final bool institutionMatchesAsset;

  /// Whether this row can be imported.
  bool get canImport =>
      assetExists && assetHasInstitution && institutionMatchesAsset;

  @override
  List<Object?> get props => [
    row,
    assetExists,
    institutionIsNew,
    assetHasInstitution,
    institutionMatchesAsset,
  ];
}

/// What a transaction import would do, computed without persisting. Import is
/// blocked while any row references a missing asset.
class TransactionImportPreview extends Equatable {
  /// Creates a preview.
  const TransactionImportPreview({required this.rows});

  /// Per-row breakdown, in file order.
  final List<TransactionImportPreviewRow> rows;

  /// One transaction is created per row.
  int get transactionCount => rows.length;

  /// Distinct institutions that don't exist yet (each created once).
  int get newInstitutionCount => rows
      .where((r) => r.institutionIsNew)
      .map((r) => r.row.institutionName.toLowerCase())
      .toSet()
      .length;

  /// Distinct tickers whose asset isn't registered yet — blockers for import.
  List<String> get missingTickers {
    final seen = <String>{};
    final out = <String>[];
    for (final r in rows.where((r) => !r.assetExists)) {
      if (seen.add(r.row.ticker.toLowerCase())) out.add(r.row.ticker);
    }
    return out;
  }

  /// Distinct tickers whose registered asset has no institution link.
  List<String> get unlinkedTickers {
    final seen = <String>{};
    final out = <String>[];
    for (final r in rows.where(
      (r) => r.assetExists && !r.assetHasInstitution,
    )) {
      if (seen.add(r.row.ticker.toLowerCase())) out.add(r.row.ticker);
    }
    return out;
  }

  /// Distinct tickers whose CSV institution differs from the asset institution.
  List<String> get institutionMismatchTickers {
    final seen = <String>{};
    final out = <String>[];
    for (final r in rows.where(
      (r) =>
          r.assetExists && r.assetHasInstitution && !r.institutionMatchesAsset,
    )) {
      if (seen.add(r.row.ticker.toLowerCase())) out.add(r.row.ticker);
    }
    return out;
  }

  /// Whether the import can proceed: rows present and no blocked row.
  bool get canImport => rows.isNotEmpty && rows.every((r) => r.canImport);

  /// Whether nothing is left to import.
  bool get isEmpty => rows.isEmpty;

  /// A copy with the row at [index] dropped.
  TransactionImportPreview withoutRowAt(int index) {
    final next = List.of(rows)..removeAt(index);
    return TransactionImportPreview(rows: next);
  }

  @override
  List<Object?> get props => [rows];
}

/// Tally of what a transaction import created.
class TransactionImportResult extends Equatable {
  /// Creates a result.
  const TransactionImportResult({
    required this.transactionsCreated,
    required this.institutionsCreated,
  });

  /// Transactions created (one per row).
  final int transactionsCreated;

  /// New institutions created (name not seen before).
  final int institutionsCreated;

  @override
  List<Object?> get props => [transactionsCreated, institutionsCreated];
}
