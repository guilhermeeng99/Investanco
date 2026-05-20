import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/money.dart';

/// The kind of transaction. Named [AssetTransaction] (not `Transaction`) to
/// avoid clashing with Drift's `Transaction` type in the data layer.
enum TransactionKind { buy, sell, dividend }

/// A buy/sell/dividend event that builds a position. Source of truth for
/// holdings. See `docs/specs/transactions.md`.
class AssetTransaction extends Equatable {
  /// Creates a transaction.
  const AssetTransaction({
    required this.id,
    required this.institutionId,
    required this.assetId,
    required this.kind,
    required this.quantity,
    required this.unitPrice,
    required this.fees,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  /// Stable unique id.
  final String id;

  /// Institution where it happened.
  final String institutionId;

  /// Asset traded.
  final String assetId;

  /// buy / sell / dividend.
  final TransactionKind kind;

  /// Units traded (fractional allowed). Ignored for dividends.
  final double quantity;

  /// Price per unit in the asset's native currency.
  final Money unitPrice;

  /// Brokerage/other fees.
  final Money fees;

  /// For dividends: total received. For buy/sell: `quantity * unitPrice`.
  final Money amount;

  /// When the transaction occurred (not in the future).
  final DateTime date;

  /// Optional free-text note.
  final String? notes;

  /// Audit timestamps.
  final DateTime createdAt;

  /// Audit timestamps.
  final DateTime updatedAt;

  /// Returns a copy with the given fields replaced.
  AssetTransaction copyWith({
    String? institutionId,
    String? assetId,
    TransactionKind? kind,
    double? quantity,
    Money? unitPrice,
    Money? fees,
    Money? amount,
    DateTime? date,
    String? notes,
    DateTime? updatedAt,
  }) {
    return AssetTransaction(
      id: id,
      institutionId: institutionId ?? this.institutionId,
      assetId: assetId ?? this.assetId,
      kind: kind ?? this.kind,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      fees: fees ?? this.fees,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        institutionId,
        assetId,
        kind,
        quantity,
        unitPrice,
        fees,
        amount,
        date,
        notes,
        createdAt,
        updatedAt,
      ];
}
