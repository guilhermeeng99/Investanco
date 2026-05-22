import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';

/// Runs a local database [write] (insert/delete + best-effort cloud mirror),
/// returning [unit] on success or a [CacheFailure] if it throws. Centralizes the
/// try/catch every repository write shares, so adapters keep only their query.
Future<Either<Failure, Unit>> guardedWrite(
  Future<void> Function() write,
) async {
  try {
    await write();
    return const Right(unit);
  } on Exception {
    // Only catch I/O-style failures (Drift/Firestore throw Exceptions). Errors
    // (StateError, type errors) signal bugs and must propagate, not be masked
    // as a CacheFailure.
    return const Left(CacheFailure());
  }
}

/// Runs a local database [read], returning its value or a [CacheFailure] if it
/// throws. The read counterpart to [guardedWrite] (same Exception-only policy).
Future<Either<Failure, T>> guardedRead<T>(
  Future<T> Function() read,
) async {
  try {
    return Right(await read());
  } on Exception {
    return const Left(CacheFailure());
  }
}

/// Deletes a parent row unless a child still references it: returns an
/// [InUseFailure] (skipping the delete) when [isReferenced] resolves true, [unit]
/// on success, or a [CacheFailure] if either step throws. Shared by the
/// institution and asset repositories, whose deletes differ only in the
/// referencing query.
Future<Either<Failure, Unit>> guardedDeleteIfUnreferenced({
  required Future<bool> Function() isReferenced,
  required Future<void> Function() delete,
}) async {
  try {
    if (await isReferenced()) return const Left(InUseFailure());
    await delete();
    return const Right(unit);
  } on Exception {
    return const Left(CacheFailure());
  }
}
