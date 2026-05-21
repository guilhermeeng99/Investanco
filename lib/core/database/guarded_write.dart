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
