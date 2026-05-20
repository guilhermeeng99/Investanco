import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
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
    try {
      final row = _toRow(asset);
      await _db.into(_db.assets).insertOnConflictUpdate(row);
      await _mirror.upsert(_collection, row.id, row.toJson());
      return const Right(unit);
    } on Object {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      final referencing = await (_db.select(_db.transactions)
            ..where((t) => t.assetId.equals(id))
            ..limit(1))
          .get();
      if (referencing.isNotEmpty) return const Left(InUseFailure());

      await (_db.delete(_db.assets)..where((t) => t.id.equals(id))).go();
      await _mirror.delete(_collection, id);
      return const Right(unit);
    } on Object {
      return const Left(CacheFailure());
    }
  }

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
