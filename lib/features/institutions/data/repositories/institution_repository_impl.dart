import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';

/// Drift-backed [InstitutionRepository]. [AppDatabase] is the local source of
/// truth; each write is also mirrored to the cloud via [RemoteMirror] so edits
/// sync immediately (see `docs/specs/cloud_sync.md`).
class InstitutionRepositoryImpl implements InstitutionRepository {
  /// Creates the repository over [_db], mirroring writes via [_mirror].
  const InstitutionRepositoryImpl(
    this._db, [
    this._mirror = const NoopRemoteMirror(),
  ]);

  final AppDatabase _db;
  final RemoteMirror _mirror;

  static const _collection = 'institutions';

  @override
  Stream<List<Institution>> watchAll() {
    final query = _db.select(_db.institutions)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(Institution institution) =>
      guardedWrite(() async {
        final row = _toRow(institution);
        await _db.into(_db.institutions).insertOnConflictUpdate(row);
        await _mirror.upsert(_collection, row.id, row.toJson());
      });

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      final referencing = await (_db.select(_db.transactions)
            ..where((t) => t.institutionId.equals(id))
            ..limit(1))
          .get();
      if (referencing.isNotEmpty) return const Left(InUseFailure());

      await (_db.delete(_db.institutions)..where((t) => t.id.equals(id))).go();
      await _mirror.delete(_collection, id);
      return const Right(unit);
    } on Object {
      return const Left(CacheFailure());
    }
  }

  Institution _toEntity(InstitutionRow row) {
    return Institution(
      id: row.id,
      name: row.name,
      kind: InstitutionKind.values.byName(row.kind),
      currency: Currency.values.byName(row.currency),
      createdAt: row.createdAt,
    );
  }

  InstitutionRow _toRow(Institution i) {
    return InstitutionRow(
      id: i.id,
      name: i.name,
      kind: i.kind.name,
      currency: i.currency.name,
      createdAt: i.createdAt,
    );
  }
}
