import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

/// Mirrors a single Drift row to `users/{uid}/{collection}/{id}` the moment it
/// changes, so cloud data tracks local edits live (not only at startup).
///
/// **Best-effort**: a failure (offline, transient, permission) is swallowed —
/// local Drift is the source of truth, and the startup bulk sync reconciles on
/// the next launch. No-op when signed out. See `docs/specs/cloud_sync.md`.
class FirestoreRemoteMirror implements RemoteMirror {
  /// Creates the mirror over [_firestore], scoped to [_auth]'s current user.
  FirestoreRemoteMirror(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  DocumentReference<Map<String, dynamic>>? _doc(String collection, String id) {
    final uid = _auth.currentUser?.userId;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(id);
  }

  @override
  Future<void> upsert(
    String collection,
    String id,
    Map<String, dynamic> json,
  ) async {
    final doc = _doc(collection, id);
    if (doc == null) return;
    try {
      await doc.set(json);
    } on Object {
      // Swallowed on purpose — startup sync reconciles on the next launch.
    }
  }

  @override
  Future<void> delete(String collection, String id) async {
    final doc = _doc(collection, id);
    if (doc == null) return;
    try {
      await doc.delete();
    } on Object {
      // Swallowed on purpose.
    }
  }
}
