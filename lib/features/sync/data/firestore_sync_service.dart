import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';

/// Firestore implementation of [SyncService].
///
/// Firestore is the **source of truth**. [sync] is an authoritative pull: it
/// fetches every mirrored collection and rebuilds the local Drift cache to match
/// exactly, so creates, edits **and** deletes made on any device are reflected.
/// There is no push — repository writes are write-through to Firestore (see
/// `RemoteMirror`). Mirrors financo's `fullSync`. See `docs/specs/cloud_sync.md`.
class FirestoreSyncService implements SyncService {
  /// Creates the service over the local [_db] and [_firestore].
  FirestoreSyncService(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;

  static const List<String> _mirroredCollections = [
    'institutions',
    'assets',
    'transactions',
    'snapshots',
    'asset_classes',
  ];

  @override
  Future<Either<Failure, Unit>> sync(String userId) async {
    try {
      // Phase 1 — fetch from Firestore (network, may throw).
      final institutions = await _fetchRows(
        userId,
        'institutions',
        InstitutionRow.fromJson,
      );
      final assets = await _fetchRows(userId, 'assets', AssetRow.fromJson);
      final transactions = await _fetchRows(
        userId,
        'transactions',
        TransactionRow.fromJson,
      );
      final snapshots = await _fetchRows(
        userId,
        'snapshots',
        SnapshotRow.fromJson,
      );
      final assetClasses = await _fetchRows(
        userId,
        'asset_classes',
        AssetClassRow.fromJson,
      );

      // Phase 2 — rebuild the local cache to match the cloud exactly.
      await _db.replaceMirroredData(
        institutions: institutions,
        assets: assets,
        transactions: transactions,
        snapshots: snapshots,
        assetClasses: assetClasses,
      );
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

  Future<List<T>> _fetchRows<T>(
    String userId,
    String name,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final snapshot = await _collection(userId, name).get();
    return snapshot.docs.map((doc) => fromJson(doc.data())).toList();
  }

  CollectionReference<Map<String, dynamic>> _collection(
    String userId,
    String name,
  ) =>
      _firestore.collection('users').doc(userId).collection(name);

  /// Firestore caps a [WriteBatch] at 500 operations. Delete in chunks so large
  /// portfolios (e.g. an active trader with >500 transactions) clear in full
  /// instead of throwing once the batch overflows.
  static const _batchLimit = 500;

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();
    final docs = snapshot.docs;
    for (var start = 0; start < docs.length; start += _batchLimit) {
      final end =
          start + _batchLimit < docs.length ? start + _batchLimit : docs.length;
      final batch = _firestore.batch();
      for (final doc in docs.sublist(start, end)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
