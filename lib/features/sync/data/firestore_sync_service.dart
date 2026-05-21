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

  static const _mirroredCollections = [
    'institutions',
    'assets',
    'transactions',
    'snapshots',
  ];

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

  @override
  Future<Either<Failure, Unit>> clear(String userId) async {
    try {
      for (final name in _mirroredCollections) {
        await _deleteCollection(_collection(userId, name));
      }
      await _db.clearUserData();
      return const Right(unit);
    } on Object {
      return const Left(ServerFailure('Clear failed'));
    }
  }

  @override
  Future<void> resetLocal() => _db.clearUserData();

  /// Firestore caps a [WriteBatch] at 500 operations. Commit in chunks so large
  /// portfolios (e.g. an active trader with >500 transactions) still push and
  /// clear in full instead of throwing once the batch overflows.
  static const _batchLimit = 500;

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    await _commitInChunks(
      snapshot.docs,
      (batch, doc) => batch.delete(doc.reference),
    );
  }

  /// Splits [items] into ≤[_batchLimit] groups and commits one batch each.
  Future<void> _commitInChunks<T>(
    List<T> items,
    void Function(WriteBatch batch, T item) op,
  ) async {
    for (var start = 0; start < items.length; start += _batchLimit) {
      final end =
          start + _batchLimit < items.length ? start + _batchLimit : items.length;
      final batch = _firestore.batch();
      for (final item in items.sublist(start, end)) {
        op(batch, item);
      }
      await batch.commit();
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
  ) {
    return _commitInChunks(
      rows,
      (batch, row) => batch.set(collection.doc(id(row)), toJson(row)),
    );
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
