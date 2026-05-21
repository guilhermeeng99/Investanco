import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';

/// Drift-backed [SnapshotRepository]. Keyed by `yyyy-MM-dd` for one row per day.
/// Each write is mirrored to the cloud via [RemoteMirror] (see `cloud_sync.md`).
class SnapshotRepositoryImpl implements SnapshotRepository {
  /// Creates the repository over [_db], mirroring writes via [_mirror].
  const SnapshotRepositoryImpl(
    this._db, [
    this._mirror = const NoopRemoteMirror(),
  ]);

  final AppDatabase _db;
  final RemoteMirror _mirror;

  static const _collection = 'snapshots';

  @override
  Future<Either<Failure, Unit>> upsertToday({
    required Money totalValue,
    required Money totalInvested,
    required Money totalPL,
  }) =>
      guardedWrite(() async {
        final now = DateTime.now();
        final day = DateTime(now.year, now.month, now.day);
        final row = SnapshotRow(
          id: _key(day),
          date: day,
          totalValueMinor: totalValue.minorUnits,
          totalInvestedMinor: totalInvested.minorUnits,
          totalPlMinor: totalPL.minorUnits,
          currency: totalValue.currency.name,
        );
        await _db.into(_db.snapshots).insertOnConflictUpdate(row);
        await _mirror.upsert(_collection, row.id, row.toJson());
      });

  @override
  Future<Either<Failure, List<Snapshot>>> range(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final rows = await (_db.select(_db.snapshots)
            ..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.date)]))
          .get();
      return Right(rows.map(_toEntity).toList());
    } on Object {
      return const Left(CacheFailure());
    }
  }

  Snapshot _toEntity(SnapshotRow row) {
    final currency = Currency.values.byName(row.currency);
    return Snapshot(
      date: row.date,
      totalValue: Money(row.totalValueMinor, currency),
      totalInvested: Money(row.totalInvestedMinor, currency),
      totalPL: Money(row.totalPlMinor, currency),
    );
  }

  String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
