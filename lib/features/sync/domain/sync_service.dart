// Single-method port so it can be faked in tests.
// ignore_for_file: one_member_abstracts
import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';

/// Mirrors local Drift data to the signed-in user's Firestore and back.
/// See `docs/specs/cloud_sync.md`.
abstract class SyncService {
  /// Pulls remote → local, then pushes local → remote, for [userId].
  Future<Either<Failure, Unit>> sync(String userId);
}
