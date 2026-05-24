import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

/// Accounts allowed to use this single-owner app. This client-side check gives
/// anyone else a clear sign-in error instead of an empty app; `firestore.rules`
/// enforces the same restriction server-side (the real protection). Compared
/// case-insensitively. (Forks: replace with your own e-mail, or inject
/// `allowedEmails` via DI.)
const _ownerEmails = {'guilhermeeng99@gmail.com'};

/// Firebase Auth + Google sign-in implementation of [AuthRepository].
///
/// Platform-split (mirrors financo): a Firebase popup on web, the native
/// `google_sign_in` flow on mobile. The native mobile flow is required —
/// `signInWithProvider` on Android opens a Custom Tab web redirect through
/// `firebaseapp.com/__/auth/handler`, which fails with "missing initial state"
/// in storage-partitioned browsers. See `docs/specs/auth.md`.
class FirebaseAuthRepository implements AuthRepository {
  /// Creates the repository over [fb.FirebaseAuth] and [GoogleSignIn]. The
  /// optional allow-list restricts sign-in to the owner account(s).
  FirebaseAuthRepository(
    this._auth,
    this._googleSignIn, [
    this._allowedEmails = _ownerEmails,
  ]);

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final Set<String> _allowedEmails;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> watchAuthState() => _auth.authStateChanges().map(_toUser);

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    try {
      final credential = kIsWeb ? await _signInWeb() : await _signInMobile();
      final user = _toUser(credential.user);
      if (user == null) return const Left(ServerFailure('Sign-in failed'));
      if (!_isAllowed(user.email)) {
        // Wrong account: drop the session so the intruder is not left signed in,
        // and report a clear error instead of an empty app. `firestore.rules`
        // denies their data server-side regardless.
        await signOut();
        return const Left(UnauthorizedFailure());
      }
      return Right(user);
    } on fb.FirebaseAuthException catch (error) {
      return Left(ServerFailure(error.message ?? 'Sign-in failed'));
    } on GoogleSignInException catch (error) {
      // User dismissed the native chooser, or the SDK rejected the request.
      return Left(ServerFailure(error.description ?? 'Sign-in cancelled'));
    } on Object {
      return const Left(ServerFailure('Sign-in failed'));
    }
  }

  /// Web: Firebase owns the Google Identity Services lifecycle via the popup.
  /// `prompt=select_account` forces the chooser so a user can switch accounts
  /// after sign-out (Firebase's `signOut` clears its session, not Google's).
  Future<fb.UserCredential> _signInWeb() {
    final provider = fb.GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    return _auth.signInWithPopup(provider);
  }

  /// Mobile: native account chooser via `google_sign_in`, then exchange the
  /// Google id token for a Firebase credential. Avoids the web-redirect handler.
  Future<fb.UserCredential> _signInMobile() async {
    final googleUser = await _googleSignIn.authenticate();
    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    // Mobile: clear Google's own session too, so the next sign-in shows the
    // account chooser instead of silently re-authenticating the last user. On
    // web GoogleSignIn is never initialised (its signOut would throw), so skip
    // it. Non-fatal: catch Object so an SDK Error can't block Firebase sign-out.
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } on Object {
        // Google sign-out failure must not stop the Firebase sign-out below.
      }
    }
    await _auth.signOut();
  }

  /// Whether [email] is on the owner allow-list (case-insensitive).
  bool _isAllowed(String email) => _allowedEmails.contains(email.toLowerCase());

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
