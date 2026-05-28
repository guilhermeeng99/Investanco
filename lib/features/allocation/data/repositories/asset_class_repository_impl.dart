import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/sync/mirrored_collections.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/allocation/domain/entities/asset_class.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';

/// Drift-backed [AssetClassRepository], mirroring each write to Firestore via
/// [RemoteMirror] (write-through). See `docs/specs/allocation.md`.
class AssetClassRepositoryImpl implements AssetClassRepository {
  /// Creates the repository over [_db], mirroring writes via [_mirror].
  const AssetClassRepositoryImpl(
    this._db, [
    this._mirror = const NoopRemoteMirror(),
  ]);

  final AppDatabase _db;
  final RemoteMirror _mirror;

  static const String _collection = MirroredCollections.assetClasses;

  @override
  Stream<List<AssetClass>> watchAll() {
    final query = _db.select(_db.assetClasses)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(AssetClass assetClass) {
    final row = _toRow(assetClass);
    return guardedMirroredUpsert(
      mirror: _mirror,
      collection: _collection,
      id: row.id,
      json: row.toJson(),
      localUpsert: () => _db.into(_db.assetClasses).insertOnConflictUpdate(row),
    );
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) => guardedWrite(() async {
        // Cascade: remove the class and any subclasses pointing at it.
        final children = await (_db.select(_db.assetClasses)
              ..where((t) => t.parentId.equals(id)))
            .get();
        for (final child in children) {
          await _mirror.delete(_collection, child.id);
        }
        await _mirror.delete(_collection, id);
        await (_db.delete(_db.assetClasses)
              ..where((t) => t.id.equals(id) | t.parentId.equals(id)))
            .go();
      });

  AssetClass _toEntity(AssetClassRow row) => AssetClass(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        colorValue: row.colorValue,
        targetPercent: row.targetPercent,
        parentId: row.parentId,
        createdAt: row.createdAt,
      );

  AssetClassRow _toRow(AssetClass c) => AssetClassRow(
        id: c.id,
        name: c.name,
        iconKey: c.iconKey,
        colorValue: c.colorValue,
        targetPercent: c.targetPercent,
        parentId: c.parentId,
        createdAt: c.createdAt,
      );
}
