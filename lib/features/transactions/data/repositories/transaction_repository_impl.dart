import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';

/// Drift-backed [TransactionRepository]. Each write is mirrored to the cloud via
/// [RemoteMirror] so edits sync immediately (see `cloud_sync.md`).
class TransactionRepositoryImpl implements TransactionRepository {
  /// Creates the repository over [_db], mirroring writes via [_mirror].
  const TransactionRepositoryImpl(
    this._db, [
    this._mirror = const NoopRemoteMirror(),
  ]);

  final AppDatabase _db;
  final RemoteMirror _mirror;

  static const _collection = 'transactions';

  @override
  Stream<List<AssetTransaction>> watchAll() {
    final query = _db.select(_db.transactions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<AssetTransaction>> watchByAsset(String assetId) {
    final query = _db.select(_db.transactions)
      ..where((t) => t.assetId.equals(assetId))
      ..orderBy([(t) => OrderingTerm(expression: t.date)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(AssetTransaction transaction) =>
      guardedWrite(() async {
        final row = _toRow(transaction);
        await _db.into(_db.transactions).insertOnConflictUpdate(row);
        await _mirror.upsert(_collection, row.id, row.toJson());
      });

  @override
  Future<Either<Failure, Unit>> delete(String id) => guardedWrite(() async {
        await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
        await _mirror.delete(_collection, id);
      });

  AssetTransaction _toEntity(TransactionRow row) {
    final currency = Currency.values.byName(row.currency);
    return AssetTransaction(
      id: row.id,
      institutionId: row.institutionId,
      assetId: row.assetId,
      kind: TransactionKind.values.byName(row.kind),
      quantity: row.quantity,
      unitPrice: Money(row.unitPriceMinor, currency),
      fees: Money(row.feesMinor, currency),
      amount: Money(row.amountMinor, currency),
      date: row.date,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TransactionRow _toRow(AssetTransaction tx) {
    return TransactionRow(
      id: tx.id,
      institutionId: tx.institutionId,
      assetId: tx.assetId,
      kind: tx.kind.name,
      quantity: tx.quantity,
      unitPriceMinor: tx.unitPrice.minorUnits,
      feesMinor: tx.fees.minorUnits,
      amountMinor: tx.amount.minorUnits,
      currency: tx.unitPrice.currency.name,
      date: tx.date,
      notes: tx.notes,
      createdAt: tx.createdAt,
      updatedAt: tx.updatedAt,
    );
  }
}
