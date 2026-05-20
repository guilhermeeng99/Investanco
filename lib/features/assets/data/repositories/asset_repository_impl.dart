import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';

/// Drift-backed [AssetRepository]. Metadata is stored as a JSON string.
class AssetRepositoryImpl implements AssetRepository {
  /// Creates the repository over [_db].
  const AssetRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Asset>> watchAll() {
    final query = _db.select(_db.assets)
      ..orderBy([(t) => OrderingTerm(expression: t.ticker)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(Asset asset) async {
    try {
      await _db.into(_db.assets).insertOnConflictUpdate(_toCompanion(asset));
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

  AssetsCompanion _toCompanion(Asset asset) {
    return AssetsCompanion(
      id: Value(asset.id),
      ticker: Value(asset.ticker),
      name: Value(asset.name),
      kind: Value(asset.kind.name),
      market: Value(asset.market.name),
      currency: Value(asset.currency.name),
      metadata: Value(jsonEncode(asset.metadata)),
      createdAt: Value(asset.createdAt),
    );
  }
}
