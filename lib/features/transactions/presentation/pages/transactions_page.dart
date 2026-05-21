import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/date_formatter.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/transactions_csv_import_dialog.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:investanco/features/transactions/presentation/transaction_labels.dart';
import 'package:investanco/features/transactions/presentation/transaction_visuals.dart';
import 'package:investanco/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

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
    final confirmed = await showConfirmDialog(
      context,
      title: t.transactions.title,
      message: t.transactions.deleteConfirm,
    );
    if (confirmed) await cubit.remove(id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return Scaffold(
      appBar: InvestancoAppBar(title: t.transactions.title),
      floatingActionButton: ImportAddFab(
        heroPrefix: 'transactions',
        addTooltip: t.transactions.add,
        importTooltip: t.importTransactions.title,
        onAdd: () {
          final state = cubit.state;
          if (state is TransactionsLoaded) _openForm(context, cubit, state);
        },
        onImport: () => showTransactionsCsvImportDialog(context),
      ),
      body: BlocBuilder<TransactionsCubit, TransactionsState>(
        builder: (context, state) {
          return switch (state) {
            TransactionsLoading() => const LoadingShimmerList(),
            TransactionsError() => ErrorView(
                message: t.transactions.saveError,
                onRetry: () {},
              ),
            TransactionsLoaded(:final transactions) when transactions.isEmpty =>
              _EmptyState(
                onAdd: () => _openForm(context, cubit, state),
              ),
            TransactionsLoaded() => _TransactionsList(
                state: state,
                onTap: (tx) => _openForm(context, cubit, state, existing: tx),
                onDelete: (id) => _confirmDelete(context, cubit, id),
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
  });

  final TransactionsLoaded state;
  final void Function(AssetTransaction) onTap;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    final assetById = {for (final a in state.assets) a.id: a};
    final institutionById = {for (final i in state.institutions) i.id: i};

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: state.transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = state.transactions[index];
        return _TransactionTile(
          tx: tx,
          ticker: assetById[tx.assetId]?.ticker,
          institution: institutionById[tx.institutionId]?.name,
          onTap: () => onTap(tx),
          onDelete: () => onDelete(tx.id),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.ticker,
    required this.institution,
    required this.onTap,
    required this.onDelete,
  });

  final AssetTransaction tx;
  final String? ticker;
  final String? institution;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = transactionKindColor(tx.kind, colors);
    final signed = tx.amount * transactionKindSign(tx.kind);

    return InvestancoCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          BrandAvatar(
            background: accent,
            icon: transactionKindIcon(tx.kind),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      transactionKindLabel(tx.kind),
                      style: context.textTheme.titleSmall,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ticker ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colors.onBackgroundLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${institution ?? '—'}  ·  ${formatShortDate(tx.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onBackgroundLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SignedAmount(money: signed, fontSize: 14),
          IconButton(
            tooltip: t.common.delete,
            icon: FaIcon(
              FontAwesomeIcons.trashCan,
              size: 16,
              color: colors.onBackgroundLight,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: FontAwesomeIcons.rightLeft,
      title: t.transactions.title,
      message: t.transactions.empty,
      actionLabel: t.transactions.add,
      onAction: onAdd,
    );
  }
}
