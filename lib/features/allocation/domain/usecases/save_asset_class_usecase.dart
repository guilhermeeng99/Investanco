import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';

/// Validates and persists an [AssetClass]. Validation lives here (not just the
/// form) so it can't be bypassed. See `docs/specs/allocation.md` §Validation.
class SaveAssetClassUseCase {
  /// Creates the use case.
  const SaveAssetClassUseCase(this._repository);

  final AssetClassRepository _repository;

  /// Saves [assetClass], validating against the current [existing] classes:
  /// non-empty name, target in `[0,100]`, and the class target sum staying within
  /// 100% (classes share the global budget).
  Future<Either<Failure, Unit>> call(
    AssetClass assetClass, {
    required List<AssetClass> existing,
  }) async {
    if (assetClass.name.trim().isEmpty) {
      return const Left(ValidationFailure('name'));
    }
    if (assetClass.targetPercent < 0 || assetClass.targetPercent > 100) {
      return const Left(ValidationFailure('target'));
    }

    final othersSum = existing
        .where((c) => c.id != assetClass.id)
        .fold<double>(0, (sum, c) => sum + c.targetPercent);
    if (othersSum + assetClass.targetPercent > 100.01) {
      return const Left(ValidationFailure('sum', ValidationCode.classTargetSum));
    }

    return _repository.save(assetClass);
  }
}
