import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';

part 'sync_state.dart';

/// Orchestrates cloud sync: runs once whenever a user signs in, and on demand via
/// [syncNow] (the Settings button). See `docs/specs/cloud_sync.md`.
class SyncCubit extends Cubit<SyncState> {
  /// Subscribes to auth changes on creation.
  SyncCubit(this._syncService, this._authRepository) : super(const SyncIdle()) {
    _subscription = _authRepository.watchAuthState().listen(_onAuthChanged);
  }

  final SyncService _syncService;
  final AuthRepository _authRepository;
  late final StreamSubscription<AuthUser?> _subscription;

  void _onAuthChanged(AuthUser? user) {
    if (user != null) unawaited(_run(user.userId));
  }

  /// Re-runs sync for the current user (no-op when signed out).
  Future<void> syncNow() async {
    final user = _authRepository.currentUser;
    if (user != null) await _run(user.userId);
  }

  Future<void> _run(String userId) async {
    emit(const SyncInProgress());
    final result = await _syncService.sync(userId);
    emit(
      result.fold(
        (failure) => SyncFailure(failure.message),
        (_) => SyncSuccess(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
