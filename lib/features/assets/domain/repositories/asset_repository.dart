import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';

/// Persistence contract for [Asset]. See `docs/specs/assets.md`.
abstract class AssetRepository {
  /// Reactive list of all assets, ordered by ticker.
  Stream<List<Asset>> watchAll();

  /// Creates or updates an asset (upsert).
  Future<Either<Failure, Unit>> save(Asset asset);

  /// Deletes an asset. Returns [InUseFailure] if it has transactions.
  Future<Either<Failure, Unit>> delete(String id);
}
