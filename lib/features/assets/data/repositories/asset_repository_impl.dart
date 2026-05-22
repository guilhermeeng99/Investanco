import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';

/// Drift-backed [AssetRepository]. Metadata is stored as a JSON string. Each
/// write is mirrored to the cloud via [RemoteMirror] (see `cloud_sync.md`).
class AssetRepositoryImpl implements AssetRepository {
  /// Creates the repository over [_db], mirroring writes via [_mirror].
  const AssetRepositoryImpl(
    this._db, [
    this._mirror = const NoopRemoteMirror(),
  ]);

  final AppDatabase _db;
  final RemoteMirror _mirror;

  static const _collection = 'assets';

  @override
  Stream<List<Asset>> watchAll() {
    final query = _db.select(_db.assets)
      ..orderBy([(t) => OrderingTerm(expression: t.ticker)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(Asset asset) async {
    final invalid = await _validate(asset);
    if (invalid != null) return Left(invalid);
    return guardedWrite(() async {
      final row = _toRow(asset);
      // Firestore-first (write-through): persist to the authoritative cloud
      // before caching locally, so a write that can't reach Firestore fails.
      await _mirror.upsert(_collection, row.id, row.toJson());
      await _db.into(_db.assets).insertOnConflictUpdate(row);
    });
  }

  /// Rejects a duplicate (ticker, market) (rule 2) before any write — comparing
  /// the ticker case-insensitively. Returns the blocking [Failure], or null when
  /// valid. See `docs/specs/assets.md`.
  Future<Failure?> _validate(Asset asset) async {
    final ticker = asset.ticker.trim().toUpperCase();
    final market = asset.market.name;
    try {
      final rows = await _db.select(_db.assets).get();
      final clashes = rows.any(
        (r) =>
            r.id != asset.id &&
            r.ticker.trim().toUpperCase() == ticker &&
            r.market == market,
      );
      if (clashes) {
        return const ValidationFailure(
          'An asset with this ticker already exists in this market.',
          ValidationCode.duplicateAsset,
        );
      }
    } on Exception {
      return const CacheFailure();
    }
    return null;
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) =>
      guardedDeleteIfUnreferenced(
        isReferenced: () async {
          final referencing = await (_db.select(_db.transactions)
                ..where((t) => t.assetId.equals(id))
                ..limit(1))
              .get();
          return referencing.isNotEmpty;
        },
        delete: () async {
          await _mirror.delete(_collection, id);
          await (_db.delete(_db.assets)..where((t) => t.id.equals(id))).go();
        },
      );

  Asset _toEntity(AssetRow row) {
    final decoded = jsonDecode(row.metadata) as Map<String, dynamic>;
    return Asset(
      id: row.id,
      ticker: row.ticker,
      name: row.name,
      kind: AssetKind.values.byName(row.kind),
      market: Market.values.byName(row.market),
      currency: Currency.values.byName(row.currency),
      metadata: decoded.map((key, value) => MapEntry(key, value.toString())),
      createdAt: row.createdAt,
    );
  }

  AssetRow _toRow(Asset asset) {
    return AssetRow(
      id: asset.id,
      ticker: asset.ticker,
      name: asset.name,
      kind: asset.kind.name,
      market: asset.market.name,
      currency: asset.currency.name,
      metadata: jsonEncode(asset.metadata),
      createdAt: asset.createdAt,
    );
  }
}
