import 'package:dartz/dartz.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// Persistence contract for [AssetTransaction]. See `docs/specs/transactions.md`.
abstract class TransactionRepository {
  /// Reactive list of all transactions, newest first.
  Stream<List<AssetTransaction>> watchAll();

  /// Reactive list of transactions for one asset, oldest first (for holdings).
  Stream<List<AssetTransaction>> watchByAsset(String assetId);

  /// Creates or updates a transaction (upsert).
  Future<Either<Failure, Unit>> save(AssetTransaction transaction);

  /// Deletes a transaction.
  Future<Either<Failure, Unit>> delete(String id);
}
