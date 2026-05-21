/// Port for writing a single Drift row to the user's cloud store **as it
/// changes** (write-through). Repositories call it *before* touching the local
/// cache and surface any failure: the cloud is the source of truth, so a write
/// that can't reach Firestore must fail rather than live only locally —
/// otherwise the next authoritative startup sync would wipe it. See
/// `docs/specs/cloud_sync.md`.
///
/// Implemented by `FirestoreRemoteMirror`. [NoopRemoteMirror] is the default in
/// repositories, so tests and any no-cloud build skip remote writes for free.
abstract class RemoteMirror {
  /// Allows const default instances.
  const RemoteMirror();

  /// Upserts [json] at `{collection}/{id}` for the current user. Throws on
  /// failure (offline / permission / transient) so the caller can surface it.
  Future<void> upsert(String collection, String id, Map<String, dynamic> json);

  /// Deletes `{collection}/{id}` for the current user. Throws on failure.
  Future<void> delete(String collection, String id);
}

/// No-op mirror: does nothing. Default for repositories (tests / no-cloud).
class NoopRemoteMirror implements RemoteMirror {
  /// Creates the no-op mirror.
  const NoopRemoteMirror();

  @override
  Future<void> upsert(
    String collection,
    String id,
    Map<String, dynamic> json,
  ) async {}

  @override
  Future<void> delete(String collection, String id) async {}
}
