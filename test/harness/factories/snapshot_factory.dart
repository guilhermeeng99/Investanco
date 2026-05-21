import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';

/// Test factory for [Snapshot]. Defaults to R$100 value / R$80 invested / R$20
/// P&L on 2026-05-20. Never hardcode entities in tests.
Snapshot snapshotFactory({
  DateTime? date,
  Money? totalValue,
  Money? totalInvested,
  Money? totalPL,
}) {
  const brl = Currency.brl;
  return Snapshot(
    date: date ?? DateTime(2026, 5, 20),
    totalValue: totalValue ?? Money.fromMajor(100, brl),
    totalInvested: totalInvested ?? Money.fromMajor(80, brl),
    totalPL: totalPL ?? Money.fromMajor(20, brl),
  );
}
