import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';

/// Mirrors local Drift data to the signed-in user's Firestore and back, and can
/// wipe it. See `docs/specs/cloud_sync.md`.
abstract class SyncService {
  /// Pulls remote → local, rebuilding the local cache for [userId]. There is no
  /// push here — writes mirror to Firestore through `RemoteMirror` as they happen.
  Future<Either<Failure, Unit>> sync(String userId);

  /// Permanently deletes the user's mirrored data — both the Firestore
  /// collections and the local Drift rows (settings are kept). No undo.
  Future<Either<Failure, Unit>> clear(String userId);

  /// Wipes only the **local** Drift rows (keeps Firestore and settings). Called
  /// on sign-out so the next account that signs in on this device starts from a
  /// clean local mirror instead of inheriting the previous user's data (the
  /// cloud is the source of truth, so re-login restores it). See
  /// `docs/specs/cloud_sync.md`.
  Future<void> resetLocal();
}
