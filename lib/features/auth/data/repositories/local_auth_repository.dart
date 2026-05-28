import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

/// A signed-out [AuthRepository] stub for tests and no-Firebase dev runs.
///
/// Reports the user as signed out and refuses sign-in with a clear message, so
/// the `AuthBloc` and login UI can be exercised without a Firebase project. The
/// production app wires `FirebaseAuthRepository` behind the same port (Firebase
/// Auth + Google sign-in is the live implementation; see `injection_container`).
class LocalAuthRepository implements AuthRepository {
  /// Creates the placeholder.
  const LocalAuthRepository();

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> watchAuthState() => Stream.value(null);

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async =>
      const Left(ServerFailure('Sign-in requires Firebase configuration'));

  @override
  Future<void> signOut() async {}
}
