import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';

/// Persistence contract for [Institution]. See `docs/specs/institutions.md`.
abstract class InstitutionRepository {
  /// Reactive list of all institutions, ordered by name.
  Stream<List<Institution>> watchAll();

  /// Creates or updates an institution (upsert).
  Future<Either<Failure, Unit>> save(Institution institution);

  /// Deletes an institution. Returns [InUseFailure] if it has transactions.
  Future<Either<Failure, Unit>> delete(String id);
}
