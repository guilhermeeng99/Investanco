import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';

/// Persistence contract for daily [Snapshot]s. See `docs/specs/snapshots.md`.
abstract class SnapshotRepository {
  /// Writes (or updates) today's snapshot — idempotent per day.
  Future<void> upsertToday({
    required Money totalValue,
    required Money totalInvested,
    required Money totalPL,
  });

  /// Snapshots within the inclusive date range, oldest first.
  Future<List<Snapshot>> range(DateTime from, DateTime to);
}
