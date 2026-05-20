import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

/// Placeholder [AuthRepository] until Firebase Auth is configured (Phase 6).
///
/// Reports the user as signed out and refuses sign-in with a clear message, so
/// the `AuthBloc` and any future login UI can be exercised without a Firebase
/// project. `FirebaseAuthRepository` replaces this behind the same port once
/// `firebase_options.dart` is provided.
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
