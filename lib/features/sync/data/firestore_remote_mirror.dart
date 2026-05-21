import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';

/// Writes a single Drift row to `users/{uid}/{collection}/{id}` the moment it
/// changes (write-through), so the cloud — the source of truth — always reflects
/// the latest edit.
///
/// Failures (offline, transient, permission) **propagate**: the repository
/// surfaces them and skips the local cache write, because the next authoritative
/// startup sync rebuilds local from Firestore and would otherwise wipe a
/// cloud-less row. No-op when signed out. See `docs/specs/cloud_sync.md`.
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
    if (doc == null) return; // signed out → no-op
    await doc.set(json);
  }

  @override
  Future<void> delete(String collection, String id) async {
    final doc = _doc(collection, id);
    if (doc == null) return; // signed out → no-op
    await doc.delete();
  }
}
