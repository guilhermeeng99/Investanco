import 'package:equatable/equatable.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';

/// State for the transactions cubit. Carries the related assets/institutions so
/// the list can resolve names and the form can offer pickers.
sealed class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state (waiting for all three streams).
class TransactionsLoading extends TransactionsState {
  /// Creates the loading state.
  const TransactionsLoading();
}

/// Loaded with transactions and their related entities.
class TransactionsLoaded extends TransactionsState {
  /// Creates the loaded state.
  const TransactionsLoaded({
    required this.transactions,
    required this.assets,
    required this.institutions,
    this.institutionFilter,
  });

  /// Transactions, newest first.
  final List<AssetTransaction> transactions;

  /// All assets (for name resolution and the form picker).
  final List<Asset> assets;

  /// All institutions (for name resolution and the form picker).
  final List<Institution> institutions;

  /// Active institution filter (an institution id), or `null` for all. Kept
  /// separate from [transactions] so the page can distinguish "no transactions
  /// at all" from "none match the current filter".
  final String? institutionFilter;

  /// [transactions] narrowed to [institutionFilter] (newest first). Returns the
  /// full list when no filter is active.
  List<AssetTransaction> get visibleTransactions {
    final filter = institutionFilter;
    if (filter == null) return transactions;
    return transactions
        .where((tx) => tx.institutionId == filter)
        .toList(growable: false);
  }

  @override
  List<Object?> get props =>
      [transactions, assets, institutions, institutionFilter];
}

/// A backing stream failed.
class TransactionsError extends TransactionsState {
  /// Creates the error state.
  const TransactionsError();
}
