/// Port for mirroring a single Drift row to the user's cloud store **as it
/// changes**, so edits sync immediately (not only at startup). Repositories call
/// it after a local write; the bulk startup sync (see `docs/specs/cloud_sync.md`)
/// still reconciles anything missed (e.g. offline edits).
///
/// Implemented by `FirestoreRemoteMirror`. [NoopRemoteMirror] is the default in
/// repositories, so tests and any no-cloud build skip remote writes for free.
abstract class RemoteMirror {
  /// Allows const default instances.
  const RemoteMirror();

  /// Upserts [json] at `{collection}/{id}` for the current user. Best-effort.
  Future<void> upsert(String collection, String id, Map<String, dynamic> json);

  /// Deletes `{collection}/{id}` for the current user. Best-effort.
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
