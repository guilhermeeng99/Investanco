import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';

/// Port for authentication. Implemented by `FirebaseAuthRepository` (Google
/// sign-in); `LocalAuthRepository` is a stub for tests/dev. See `docs/specs/auth.md`.
abstract class AuthRepository {
  /// Emits the signed-in user, or null when signed out. Emits on every change.
  Stream<AuthUser?> watchAuthState();

  /// The current user, or null when signed out.
  AuthUser? get currentUser;

  /// Starts the Google sign-in flow.
  Future<Either<Failure, AuthUser>> signInWithGoogle();

  /// Signs the current user out.
  Future<void> signOut();
}
