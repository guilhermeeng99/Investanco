import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';

/// Persistence contract for daily [Snapshot]s. See `docs/specs/snapshots.md`.
abstract class SnapshotRepository {
  /// Writes (or updates) today's snapshot — idempotent per day.
  Future<Either<Failure, Unit>> upsertToday({
    required Money totalValue,
    required Money totalInvested,
    required Money totalPL,
  });

  /// Snapshots within the inclusive date range, oldest first.
  Future<Either<Failure, List<Snapshot>>> range(DateTime from, DateTime to);
}
