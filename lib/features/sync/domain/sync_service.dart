import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';

/// Mirrors local Drift data to the signed-in user's Firestore and back, and can
/// wipe it. See `docs/specs/cloud_sync.md`.
abstract class SyncService {
  /// Pulls remote → local, then pushes local → remote, for [userId].
  Future<Either<Failure, Unit>> sync(String userId);

  /// Permanently deletes the user's mirrored data — both the Firestore
  /// collections and the local Drift rows (settings are kept). No undo.
  Future<Either<Failure, Unit>> clear(String userId);
}
