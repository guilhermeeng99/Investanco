import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/money.dart';

/// A daily record of total portfolio value (base currency). See
/// `docs/specs/snapshots.md`.
class Snapshot extends Equatable {
  /// Creates a snapshot.
  const Snapshot({
    required this.date,
    required this.totalValue,
    required this.totalInvested,
    required this.totalPL,
  });

  /// Capture date (local midnight).
  final DateTime date;

  /// Total portfolio value.
  final Money totalValue;

  /// Total cost basis.
  final Money totalInvested;

  /// Total profit/loss (unrealized).
  final Money totalPL;

  @override
  List<Object?> get props => [date, totalValue, totalInvested, totalPL];
}
