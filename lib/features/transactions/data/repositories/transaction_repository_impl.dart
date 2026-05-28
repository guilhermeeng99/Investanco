import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/database/guarded_write.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/sync/mirrored_collections.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/oversell_check.dart';
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

  static const String _collection = MirroredCollections.transactions;

  @override
  Stream<List<AssetTransaction>> watchAll() {
    final query = _db.select(_db.transactions)
      ..orderBy([
        (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
      ]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Either<Failure, Unit>> save(AssetTransaction transaction) async {
    final invalid = await _validate(transaction);
    if (invalid != null) return Left(invalid);
    final row = _toRow(transaction);
    return guardedMirroredUpsert(
      mirror: _mirror,
      collection: _collection,
      id: row.id,
      json: row.toJson(),
      localUpsert: () => _db.into(_db.transactions).insertOnConflictUpdate(row),
    );
  }

  /// Enforces the domain invariants before any write, so both the form and the
  /// CSV import are guarded: a positive quantity for buy/sell (rule 1), no
  /// future date (rule 4), and no sell exceeding the quantity held in its
  /// (asset, institution) position on its date (rule 2). Returns the blocking
  /// [Failure], or null when valid. See `docs/specs/transactions.md`.
  Future<Failure?> _validate(AssetTransaction tx) async {
    if (tx.date.isAfter(DateTime.now())) {
      return const ValidationFailure(
        'A transaction cannot be dated in the future.',
        ValidationCode.futureTransactionDate,
      );
    }
    // Dividends never change quantity; only a sell (directly) or a buy edit
    // (stranding a later sell) can break the position's timeline.
    if (tx.kind == TransactionKind.dividend) return null;
    // A buy/sell must move a positive quantity (rule 1) — guard here so the
    // interactive form is covered too, not just the CSV parser.
    if (tx.quantity <= 0) {
      return const ValidationFailure(
        'A buy or sell must have a quantity greater than zero.',
        ValidationCode.nonPositiveQuantity,
      );
    }
    final List<AssetTransaction> position;
    try {
      final stored = await (_db.select(_db.transactions)
            ..where(
              (t) =>
                  t.assetId.equals(tx.assetId) &
                  t.institutionId.equals(tx.institutionId),
            ))
          .get();
      position = [
        for (final row in stored.where((r) => r.id != tx.id)) _toEntity(row),
        tx,
      ];
    } on Exception {
      return const CacheFailure();
    }
    if (oversellsTimeline(position)) {
      return const ValidationFailure(
        'A sell cannot exceed the quantity held on its date.',
        ValidationCode.oversell,
      );
    }
    return null;
  }

  @override
  Future<Either<Failure, Unit>> delete(String id) => guardedWrite(() async {
        await _mirror.delete(_collection, id);
        await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
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
