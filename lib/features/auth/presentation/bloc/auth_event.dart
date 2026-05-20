part of 'auth_bloc.dart';

/// Authentication events. See `docs/specs/auth.md`.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the auth state stream (dispatch once at startup).
class AuthStarted extends AuthEvent {
  /// Creates the event.
  const AuthStarted();
}

/// The user tapped "sign in with Google".
class AuthSignInRequested extends AuthEvent {
  /// Creates the event.
  const AuthSignInRequested();
}

/// The user tapped "sign out".
class AuthSignOutRequested extends AuthEvent {
  /// Creates the event.
  const AuthSignOutRequested();
}

/// Internal: the repository stream reported a new user (or null).
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}
