import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';

/// Drift-backed [InstitutionRepository]. The [AppDatabase] is the local data
/// source; rows are mapped to/from the domain [Institution].
class InstitutionRepositoryImpl implements InstitutionRepository {
  /// Creates the repository over [_db].
  const InstitutionRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Institution>> watchAll() {
    final query = _db.select(_db.institutions)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(Institution institution) async {
    try {
      await _db
          .into(_db.institutions)
          .insertOnConflictUpdate(_toCompanion(institution));
      return const Right(unit);
    } on Object {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      final referencing = await (_db.select(_db.transactions)
            ..where((t) => t.institutionId.equals(id))
            ..limit(1))
          .get();
      if (referencing.isNotEmpty) return const Left(InUseFailure());

      await (_db.delete(_db.institutions)..where((t) => t.id.equals(id))).go();
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

  InstitutionsCompanion _toCompanion(Institution i) {
    return InstitutionsCompanion(
      id: Value(i.id),
      name: Value(i.name),
      kind: Value(i.kind.name),
      currency: Value(i.currency.name),
      createdAt: Value(i.createdAt),
    );
  }
}
