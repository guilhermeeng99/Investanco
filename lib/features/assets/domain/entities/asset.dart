import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/currency.dart';

/// Instrument classification; decides which pricing source values it.
enum AssetKind {
  stockBr,
  fiiBr,
  etfBr,
  bdrBr,
  stockUs,
  etfUs,
  crypto,
  treasury,
  fixedIncome,
  fund,
  cash;

  /// Kinds the asset form's Type picker offers. The enum keeps every kind so
  /// existing assets (and CSV import) still deserialize, display and value
  /// correctly — this only narrows what users can *create* to the kinds in
  /// active use. Re-add a kind here to surface it again; no data migration.
  static const List<AssetKind> selectableKinds = [
    etfUs,
    crypto,
    fixedIncome,
  ];
}

/// Trading venue / origin of an asset.
enum Market { br, us, global }

/// A tradable instrument the user owns. See `docs/specs/assets.md`.
class Asset extends Equatable {
  /// Creates an asset.
  const Asset({
    required this.id,
    required this.ticker,
    required this.name,
    required this.kind,
    required this.market,
    required this.currency,
    required this.createdAt,
    this.institutionId,
    this.metadata = const {},
  });

  /// Stable unique id.
  final String id;

  /// Symbol used to fetch quotes (e.g. `PETR4`, `AAPL`) or a synthetic id for
  /// non-market instruments (Tesouro, fixed income).
  final String ticker;

  /// Human-readable label.
  final String name;

  /// Instrument classification.
  final AssetKind kind;

  /// Trading venue.
  final Market market;

  /// Native quote currency.
  final Currency currency;

  /// Institution where this asset is custodied. Nullable only for legacy rows
  /// loaded before the user links them through the edit form.
  final String? institutionId;

  /// Kind-specific data (e.g. fixed-income `fiBasis`/`fiRate` via
  /// `FixedIncomeMetadata`, or `tesouroName`). See `docs/specs/assets.md`.
  final Map<String, String> metadata;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Returns a copy with the given fields replaced.
  Asset copyWith({
    String? ticker,
    String? name,
    AssetKind? kind,
    Market? market,
    Currency? currency,
    String? institutionId,
    Map<String, String>? metadata,
  }) {
    return Asset(
      id: id,
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      market: market ?? this.market,
      currency: currency ?? this.currency,
      institutionId: institutionId ?? this.institutionId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ticker,
    name,
    kind,
    market,
    currency,
    institutionId,
    metadata,
    createdAt,
  ];
}
