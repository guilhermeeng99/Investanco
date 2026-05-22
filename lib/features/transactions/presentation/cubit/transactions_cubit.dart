import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_state.dart';

/// Orchestrates transactions and the related entities needed to display and
/// create them. Combines three reactive streams.
class TransactionsCubit extends Cubit<TransactionsState> {
  /// Subscribes to transactions, assets and institutions.
  TransactionsCubit(
    this._transactionRepository,
    this._assetRepository,
    this._institutionRepository,
    this._idGenerator,
  ) : super(const TransactionsLoading()) {
    _transactionSub = _transactionRepository.watchAll().listen(
      (value) {
        _transactions = value;
        _tryEmit();
      },
      onError: _onError,
    );
    _assetSub = _assetRepository.watchAll().listen(
      (value) {
        _assets = value;
        _tryEmit();
      },
      onError: _onError,
    );
    _institutionSub = _institutionRepository.watchAll().listen(
      (value) {
        _institutions = value;
        _tryEmit();
      },
      onError: _onError,
    );
  }

  final TransactionRepository _transactionRepository;
  final AssetRepository _assetRepository;
  final InstitutionRepository _institutionRepository;
  final IdGenerator _idGenerator;

  late final StreamSubscription<List<AssetTransaction>> _transactionSub;
  late final StreamSubscription<List<Asset>> _assetSub;
  late final StreamSubscription<List<Institution>> _institutionSub;

  List<AssetTransaction>? _transactions;
  List<Asset>? _assets;
  List<Institution>? _institutions;
  String? _institutionFilter;

  /// Restricts the list to one institution (`null` clears the filter). Persists
  /// across stream re-emits until changed or the institution is deleted.
  void setInstitutionFilter(String? institutionId) {
    if (_institutionFilter == institutionId) return;
    _institutionFilter = institutionId;
    _tryEmit();
  }

  void _tryEmit() {
    final transactions = _transactions;
    final assets = _assets;
    final institutions = _institutions;
    if (transactions == null || assets == null || institutions == null) return;
    // Drop a dangling filter so a deleted institution can't strand the list on
    // an empty result the user can no longer clear (its chip is gone).
    if (_institutionFilter != null &&
        !institutions.any((i) => i.id == _institutionFilter)) {
      _institutionFilter = null;
    }
    emit(
      TransactionsLoaded(
        transactions: transactions,
        assets: assets,
        institutions: institutions,
        institutionFilter: _institutionFilter,
      ),
    );
  }

  void _onError(Object _, StackTrace _) => emit(const TransactionsError());

  /// Creates a transaction. Monetary values carry the asset's currency.
  Future<Failure?> add({
    required String institutionId,
    required String assetId,
    required TransactionKind kind,
    required double quantity,
    required Money unitPrice,
    required Money fees,
    required Money amount,
    required DateTime date,
    String? notes,
  }) {
    final now = DateTime.now();
    final transaction = AssetTransaction(
      id: _idGenerator.newId(),
      institutionId: institutionId,
      assetId: assetId,
      kind: kind,
      quantity: quantity,
      unitPrice: unitPrice,
      fees: fees,
      amount: amount,
      date: date,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    return _save(transaction);
  }

  /// Persists edits to an existing transaction.
  Future<Failure?> edit(AssetTransaction transaction) =>
      _save(transaction.copyWith(updatedAt: DateTime.now()));

  /// Deletes a transaction.
  Future<Failure?> remove(String id) async {
    final result = await _transactionRepository.delete(id);
    return result.failureOrNull;
  }

  Future<Failure?> _save(AssetTransaction transaction) async {
    final result = await _transactionRepository.save(transaction);
    return result.failureOrNull;
  }

  @override
  Future<void> close() async {
    await _transactionSub.cancel();
    await _assetSub.cancel();
    await _institutionSub.cancel();
    return super.close();
  }
}
