import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/core/format/currency_formatter.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:investanco/features/transactions/presentation/transaction_labels.dart';
import 'package:investanco/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:investanco/gen/strings.g.dart';

/// Manage transactions (buy/sell/dividend). See `docs/specs/transactions.md`.
class TransactionsPage extends StatelessWidget {
  /// Creates the page.
  const TransactionsPage({super.key});

  /// Route path.
  static const String routePath = '/transactions';

  /// Route name.
  static const String routeName = 'transactions';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransactionsCubit>(
      create: (_) => sl<TransactionsCubit>(),
      child: const _TransactionsView(),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  IconData _kindIcon(TransactionKind kind) => switch (kind) {
        TransactionKind.buy => Icons.south_west,
        TransactionKind.sell => Icons.north_east,
        TransactionKind.dividend => Icons.payments_outlined,
      };

  void _openForm(
    BuildContext context,
    TransactionsCubit cubit,
    TransactionsLoaded state, {
    AssetTransaction? existing,
  }) {
    if (state.assets.isEmpty || state.institutions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.transactions.needPrereqs)),
      );
      return;
    }
    unawaited(
      TransactionFormSheet.show(
        context,
        cubit,
        assets: state.assets,
        institutions: state.institutions,
        existing: existing,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionsCubit cubit,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.transactions.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(t.transactions.title)),
      floatingActionButton:
          BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
          if (state is! TransactionsLoaded) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _openForm(context, cubit, state),
            child: const Icon(Icons.add),
          );
        },
      ),
      body: BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
          return switch (state) {
            TransactionsLoading() =>
              const Center(child: CircularProgressIndicator()),
            TransactionsError() =>
              Center(child: Text(t.transactions.saveError)),
            TransactionsLoaded(:final transactions) when transactions.isEmpty =>
              const _EmptyState(),
            TransactionsLoaded() => _TransactionsList(
                state: state,
                onTap: (tx) => _openForm(context, cubit, state, existing: tx),
                onDelete: (id) => _confirmDelete(context, cubit, id),
                kindIcon: _kindIcon,
              ),
          };
        },
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.state,
    required this.onTap,
    required this.onDelete,
    required this.kindIcon,
  });

  final TransactionsLoaded state;
  final void Function(AssetTransaction) onTap;
  final void Function(String) onDelete;
  final IconData Function(TransactionKind) kindIcon;

  @override
  Widget build(BuildContext context) {
    final assetById = {for (final a in state.assets) a.id: a};
    final institutionById = {for (final i in state.institutions) i.id: i};

    return ListView.builder(
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        final asset = assetById[tx.assetId];
        final institution = institutionById[tx.institutionId];
        return ListTile(
          leading: Icon(kindIcon(tx.kind)),
          title: Text(
            '${transactionKindLabel(tx.kind)} · ${asset?.ticker ?? '—'}',
          ),
          subtitle: Text(
            '${institution?.name ?? '—'} · '
            '${_formatDate(tx.date)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(formatCurrency(tx.amount)),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(tx.id),
              ),
            ],
          ),
          onTap: () => onTap(tx),
        );
      },
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.transactions.empty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
