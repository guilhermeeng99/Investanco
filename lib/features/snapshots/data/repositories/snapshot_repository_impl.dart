import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/snapshots/domain/entities/snapshot.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';

/// Drift-backed [SnapshotRepository]. Keyed by `yyyy-MM-dd` for one row per day.
class SnapshotRepositoryImpl implements SnapshotRepository {
  /// Creates the repository over [_db].
  const SnapshotRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertToday({
    required Money totalValue,
    required Money totalInvested,
    required Money totalPL,
  }) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    await _db.into(_db.snapshots).insertOnConflictUpdate(
          SnapshotsCompanion(
            id: Value(_key(day)),
            date: Value(day),
            totalValueMinor: Value(totalValue.minorUnits),
            totalInvestedMinor: Value(totalInvested.minorUnits),
            totalPlMinor: Value(totalPL.minorUnits),
            currency: Value(totalValue.currency.name),
          ),
        );
  }

  @override
  Future<List<Snapshot>> range(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.snapshots)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(from) &
                t.date.isSmallerOrEqualValue(to),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.date)]))
        .get();
    return rows.map(_toEntity).toList();
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
