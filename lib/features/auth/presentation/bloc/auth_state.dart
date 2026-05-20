part of 'auth_bloc.dart';

/// Authentication state. See `docs/specs/auth.md`.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the auth stream reports anything.
class AuthUnknown extends AuthState {
  /// Creates the unknown state.
  const AuthUnknown();
}

/// A sign-in is in flight (Google provider flow open). Drives the button spinner
/// and tells the router gate to hold the user in place. See `docs/specs/auth.md`.
class AuthInProgress extends AuthState {
  /// Creates the in-progress state.
  const AuthInProgress();
}

/// A user is signed in.
class AuthAuthenticated extends AuthState {
  /// Creates the authenticated state for [user].
  const AuthAuthenticated(this.user);

  /// The signed-in user.
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// No user is signed in. [message] carries a sign-in error, when any.
class AuthUnauthenticated extends AuthState {
  /// Creates the signed-out state, optionally with an error [message].
  const AuthUnauthenticated({this.message});

  /// Error from the last sign-in attempt, or null.
  final String? message;

  @override
  List<Object?> get props => [message];
}
