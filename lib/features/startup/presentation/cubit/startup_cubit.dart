import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';

/// A step of the startup sequence. The cubit emits the step (not raw copy) so the
/// page maps it to a localized label and tests assert behaviour, not wording.
enum StartupStep {
  /// Waiting for the auth stream to resolve.
  checkingAuth,

  /// Mirroring the signed-in user's cloud data before entering.
  syncing,
}

/// Drives the splash: waits for auth to resolve, runs the cloud sync when signed
/// in, then routes. The auth gate (see `docs/specs/auth.md`) keeps the user here
/// until this resolves. See `docs/specs/startup.md`.
class StartupCubit extends Cubit<StartupState> {
  /// Creates the cubit over the app-wide [AuthBloc] and the [SyncService].
  StartupCubit(this._authBloc, this._syncService)
      : super(const StartupInitial());

  final AuthBloc _authBloc;
  final SyncService _syncService;

  /// Runs the startup sequence. Safe to call again (the error retry re-runs it).
  Future<void> initialize() async {
    emit(const StartupLoading(step: StartupStep.checkingAuth, progress: 0));

    final isAuthenticated = await _waitForAuth();
    if (!isAuthenticated) {
      emit(const StartupUnauthenticated());
      return;
    }

    // Block on the cloud mirror before entering, so the first screen is current.
    final user = (_authBloc.state as AuthAuthenticated).user;
    emit(const StartupLoading(step: StartupStep.syncing, progress: 0.3));
    final result = await _syncService.sync(user.userId);
    emit(
      result.fold(
        (failure) => StartupError(failure.message),
        (_) => StartupAuthenticated(userId: user.userId),
      ),
    );
  }

  /// Resolves to the signed-in state. Short-circuits when already terminal;
  /// otherwise awaits the first terminal state (ignoring [AuthInProgress]).
  Future<bool> _waitForAuth() async {
    final current = _authBloc.state;
    if (current is AuthAuthenticated) return true;
    if (current is AuthUnauthenticated) return false;

    final completer = Completer<bool>();
    final subscription = _authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        if (!completer.isCompleted) completer.complete(true);
      } else if (state is AuthUnauthenticated) {
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    final result = await completer.future;
    await subscription.cancel();
    return result;
  }
}

/// Startup state. See `docs/specs/startup.md`.
sealed class StartupState extends Equatable {
  const StartupState();

  @override
  List<Object?> get props => [];
}

/// Nothing has started yet.
final class StartupInitial extends StartupState {
  /// Creates the initial state.
  const StartupInitial();
}

/// A step is running, at [progress] (0–1) for the splash bar.
final class StartupLoading extends StartupState {
  /// Creates a loading state for [step] at [progress].
  const StartupLoading({required this.step, required this.progress});

  /// The current step.
  final StartupStep step;

  /// Bar fill, 0–1.
  final double progress;

  @override
  List<Object?> get props => [step, progress];
}

/// Signed in and synced; the page routes to the dashboard.
final class StartupAuthenticated extends StartupState {
  /// Creates the authenticated state for [userId].
  const StartupAuthenticated({required this.userId});

  /// The signed-in user id.
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Signed out; the page routes to the login carousel.
final class StartupUnauthenticated extends StartupState {
  /// Creates the unauthenticated state.
  const StartupUnauthenticated();
}

/// Startup failed (e.g. the sync errored); the page shows a retry.
final class StartupError extends StartupState {
  /// Creates the error state with a human-readable [message].
  const StartupError(this.message);

  /// The failure message.
  final String message;

  @override
  List<Object?> get props => [message];
}
