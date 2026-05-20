import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';

/// Drift-backed [TransactionRepository].
class TransactionRepositoryImpl implements TransactionRepository {
  /// Creates the repository over [_db].
  const TransactionRepositoryImpl(this._db);

  final AppDatabase _db;

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
  Future<Either<Failure, Unit>> save(AssetTransaction transaction) async {
    try {
      await _db
          .into(_db.transactions)
          .insertOnConflictUpdate(_toCompanion(transaction));
      return const Right(unit);
    } on Object {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) async {
    try {
      await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
      return const Right(unit);
    } on Object {
      return const Left(CacheFailure());
    }
  }

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

  TransactionsCompanion _toCompanion(AssetTransaction tx) {
    return TransactionsCompanion(
      id: Value(tx.id),
      institutionId: Value(tx.institutionId),
      assetId: Value(tx.assetId),
      kind: Value(tx.kind.name),
      quantity: Value(tx.quantity),
      unitPriceMinor: Value(tx.unitPrice.minorUnits),
      feesMinor: Value(tx.fees.minorUnits),
      amountMinor: Value(tx.amount.minorUnits),
      currency: Value(tx.unitPrice.currency.name),
      date: Value(tx.date),
      notes: Value(tx.notes),
      createdAt: Value(tx.createdAt),
      updatedAt: Value(tx.updatedAt),
    );
  }
}
