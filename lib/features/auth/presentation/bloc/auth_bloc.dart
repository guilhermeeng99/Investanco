import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/error/failure_message.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Drives the authentication state machine off an [AuthRepository]. Mirrors the
/// repository stream into states and routes sign-in/out. See `docs/specs/auth.md`.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates the bloc over [_repository] and the [_syncService] used to wipe
  /// local data on sign-out.
  AuthBloc(this._repository, this._syncService) : super(const AuthUnknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onUserChanged);
  }

  final AuthRepository _repository;
  final SyncService _syncService;
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
    emit(const AuthInProgress());
    final result = await _repository.signInWithGoogle();
    result.fold(
      // The owner-restriction error is localized; other (provider) errors keep
      // their original message. See `FirebaseAuthRepository`.
      (failure) => emit(
        AuthUnauthenticated(
          message: failure is UnauthorizedFailure
              ? failureMessage(failure)
              : failure.message,
        ),
      ),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
    // Wipe local data so the next account on this device doesn't inherit (and
    // then re-push to its own cloud) the signed-out user's portfolio. Best-effort
    // — a failed local clear must not block the sign-out itself.
    try {
      await _syncService.resetLocal();
    } on Exception {
      // Swallowed: sign-out has already happened; the next sign-in's pull
      // reconciles local state anyway.
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
