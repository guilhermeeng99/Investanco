part of 'sync_cubit.dart';

/// Cloud-sync status. See `docs/specs/cloud_sync.md`.
sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Nothing in flight (signed out, or no sync yet).
class SyncIdle extends SyncState {
  /// Creates the idle state.
  const SyncIdle();
}

/// A sync is running.
class SyncInProgress extends SyncState {
  /// Creates the in-progress state.
  const SyncInProgress();
}

/// The last sync completed at [at].
class SyncSuccess extends SyncState {
  /// Creates the success state.
  const SyncSuccess(this.at);

  /// When the sync finished.
  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// The last sync failed with [message].
class SyncFailure extends SyncState {
  /// Creates the failure state.
  const SyncFailure(this.message);

  /// Human-readable error.
  final String message;

  @override
  List<Object?> get props => [message];
}
