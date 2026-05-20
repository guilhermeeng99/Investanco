import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';

/// Firestore implementation of [SyncService]. Reads/writes Drift rows in bulk and
/// serializes them with Drift's generated `toJson`/`fromJson`. Pull upserts remote
/// docs into Drift; push batches every local row up. See `docs/specs/cloud_sync.md`.
class FirestoreSyncService implements SyncService {
  /// Creates the service over the local [_db] and [_firestore].
  FirestoreSyncService(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, Unit>> sync(String userId) async {
    try {
      await _pull(userId);
      await _push(userId);
      return const Right(unit);
    } on Object {
      return const Left(ServerFailure('Cloud sync failed'));
    }
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String userId,
    String name,
  ) =>
      _firestore.collection('users').doc(userId).collection(name);

  Future<void> _push(String userId) async {
    await _pushRows(
      _collection(userId, 'institutions'),
      await _db.select(_db.institutions).get(),
      (row) => row.id,
      (row) => row.toJson(),
    );
    await _pushRows(
      _collection(userId, 'assets'),
      await _db.select(_db.assets).get(),
      (row) => row.id,
      (row) => row.toJson(),
    );
    await _pushRows(
      _collection(userId, 'transactions'),
      await _db.select(_db.transactions).get(),
      (row) => row.id,
      (row) => row.toJson(),
    );
    await _pushRows(
      _collection(userId, 'snapshots'),
      await _db.select(_db.snapshots).get(),
      (row) => row.id,
      (row) => row.toJson(),
    );
  }

  Future<void> _pushRows<T>(
    CollectionReference<Map<String, dynamic>> collection,
    List<T> rows,
    String Function(T) id,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    if (rows.isEmpty) return;
    final batch = _firestore.batch();
    for (final row in rows) {
      batch.set(collection.doc(id(row)), toJson(row));
    }
    await batch.commit();
  }

  Future<void> _pull(String userId) async {
    await _pullRows(
      _collection(userId, 'institutions'),
      (json) => _db.into(_db.institutions).insertOnConflictUpdate(
            InstitutionRow.fromJson(json),
          ),
    );
    await _pullRows(
      _collection(userId, 'assets'),
      (json) =>
          _db.into(_db.assets).insertOnConflictUpdate(AssetRow.fromJson(json)),
    );
    await _pullRows(
      _collection(userId, 'transactions'),
      (json) => _db.into(_db.transactions).insertOnConflictUpdate(
            TransactionRow.fromJson(json),
          ),
    );
    await _pullRows(
      _collection(userId, 'snapshots'),
      (json) => _db
          .into(_db.snapshots)
          .insertOnConflictUpdate(SnapshotRow.fromJson(json)),
    );
  }

  Future<void> _pullRows(
    CollectionReference<Map<String, dynamic>> collection,
    Future<void> Function(Map<String, dynamic>) upsert,
  ) async {
    final snapshot = await collection.get();
    for (final doc in snapshot.docs) {
      await upsert(doc.data());
    }
  }
}
