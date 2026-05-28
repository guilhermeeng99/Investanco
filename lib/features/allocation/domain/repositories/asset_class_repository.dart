import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';

/// Persistence contract for [AssetClass]es. See `docs/specs/allocation.md`.
abstract class AssetClassRepository {
  /// Streams every class (roots + subclasses), ordered by creation.
  Stream<List<AssetClass>> watchAll();

  /// Creates or updates a class.
  Future<Either<Failure, Unit>> save(AssetClass assetClass);

  /// Deletes a class. Subclasses of a deleted root are removed too (cascade).
  /// Assets pointing at a deleted class are **not** rewritten — they fall back
  /// to "unallocated" automatically because the class id no longer resolves.
  Future<Either<Failure, Unit>> delete(String id);
}
