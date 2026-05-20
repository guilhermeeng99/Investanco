import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

/// Firebase Auth + Google sign-in implementation of [AuthRepository].
///
/// Uses the provider flow built into firebase_auth, so no extra `google_sign_in`
/// dependency is needed: a popup on web, the native provider flow on mobile.
/// See `docs/specs/auth.md`.
class FirebaseAuthRepository implements AuthRepository {
  /// Creates the repository over a [fb.FirebaseAuth] instance.
  FirebaseAuthRepository(this._auth);

  final fb.FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> watchAuthState() => _auth.authStateChanges().map(_toUser);

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      final provider = fb.GoogleAuthProvider();
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final user = _toUser(credential.user);
      if (user == null) return const Left(ServerFailure('Sign-in failed'));
      return Right(user);
    } on fb.FirebaseAuthException catch (error) {
      return Left(ServerFailure(error.message ?? 'Sign-in failed'));
    } on Object {
      return const Left(ServerFailure('Sign-in failed'));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _toUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      userId: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }
}
