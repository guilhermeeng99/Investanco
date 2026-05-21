import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// One parsed, not-yet-persisted asset CSV row. See `docs/specs/csv_import.md`.
class AssetImportRow extends Equatable {
  /// Creates a row.
  const AssetImportRow({
    required this.ticker,
    required this.name,
    required this.kind,
    required this.market,
    required this.currency,
  });

  /// Asset symbol (uppercased).
  final String ticker;

  /// Display name; defaults to the ticker when the column is absent.
  final String name;

  /// Asset classification.
  final AssetKind kind;

  /// Trading venue.
  final Market market;

  /// Native currency.
  final Currency currency;

  @override
  List<Object?> get props => [ticker, name, kind, market, currency];
}

/// A preview row: the parsed [row] plus whether it would create a new asset.
class AssetImportPreviewRow extends Equatable {
  /// Creates a preview row.
  const AssetImportPreviewRow({required this.row, required this.isNew});

  /// The parsed row.
  final AssetImportRow row;

  /// True when no asset with this ticker exists yet.
  final bool isNew;

  @override
  List<Object?> get props => [row, isNew];
}

/// What an asset import would do, computed without persisting.
class AssetImportPreview extends Equatable {
  /// Creates a preview.
  const AssetImportPreview({required this.rows});

  /// Per-row breakdown, in file order.
  final List<AssetImportPreviewRow> rows;

  /// Distinct new tickers (each created once).
  int get newCount => _distinct((r) => r.isNew);

  /// Distinct tickers already in the portfolio that rows reference.
  int get reusedCount => _distinct((r) => !r.isNew);

  /// Whether nothing is left to import.
  bool get isEmpty => rows.isEmpty;

  /// A copy with the row at [index] dropped.
  AssetImportPreview withoutRowAt(int index) {
    final next = List.of(rows)..removeAt(index);
    return AssetImportPreview(rows: next);
  }

  int _distinct(bool Function(AssetImportPreviewRow) where) =>
      rows.where(where).map((r) => r.row.ticker.toLowerCase()).toSet().length;

  @override
  List<Object?> get props => [rows];
}

/// Tally of what an asset import created.
class AssetImportResult extends Equatable {
  /// Creates a result.
  const AssetImportResult({required this.assetsCreated});

  /// New assets created (ticker not seen before).
  final int assetsCreated;

  @override
  List<Object?> get props => [assetsCreated];
}
