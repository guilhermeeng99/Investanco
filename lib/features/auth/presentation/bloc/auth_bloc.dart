import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives the authentication state machine off an [AuthRepository]. Mirrors the
/// repository stream into states and routes sign-in/out. See `docs/specs/auth.md`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates the bloc over [_repository].
  AuthBloc(this._repository) : super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onUserChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _subscription?.cancel();
    _subscription = _repository
        .watchAuthState()
        .listen((user) => add(_AuthUserChanged(user)));
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    emit(user == null ? const AuthUnauthenticated() : AuthAuthenticated(user));
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _repository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthUnauthenticated(message: failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
