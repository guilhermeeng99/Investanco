import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/date_formatter.dart';
import 'package:investanco/features/institutions/domain/entities/institution.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/transactions_csv_import_dialog.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_state.dart';
import 'package:investanco/features/transactions/presentation/transaction_labels.dart';
import 'package:investanco/features/transactions/presentation/transaction_visuals.dart';
import 'package:investanco/features/transactions/presentation/widgets/transaction_form_sheet.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Opens the transaction form for create/edit. Shared by [TransactionsFab] (add)
/// and the list tiles (edit); shows a snackbar when prerequisites (an asset and an
/// institution) are missing instead of an unusable empty form.
void openTransactionForm(
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
  final linkedAssets = state.assets
      .where(
        (asset) =>
            asset.institutionId != null &&
            asset.institutionId!.trim().isNotEmpty,
      )
      .toList();
  final formAssets = existing == null ? linkedAssets : state.assets;
  if (formAssets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.transactions.needLinkedAsset)),
    );
    return;
  }
  unawaited(
    TransactionFormSheet.show(
      context,
      cubit,
      assets: formAssets,
      existing: existing,
    ),
  );
}

/// The Transactions add/import FAB stack — split from [TransactionsView] so the
/// records tab can mount it in `Scaffold.floatingActionButton`. Expects a
/// [TransactionsCubit] above it in the tree.
class TransactionsFab extends StatelessWidget {
  /// Creates the FAB stack.
  const TransactionsFab({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return ImportAddFab(
      heroPrefix: 'transactions',
      addTooltip: t.transactions.add,
      importTooltip: t.importTransactions.title,
      onAdd: () {
        final state = cubit.state;
        if (state is TransactionsLoaded) {
          openTransactionForm(context, cubit, state);
        }
      },
      onImport: () => showTransactionsCsvImportDialog(context),
    );
  }
}

/// The Transactions list body — embeddable (no Scaffold) so the unified records
/// tab can host it in a `PageView`. Expects a [TransactionsCubit] above it in the
/// tree. See `docs/specs/transactions.md` and `records.md`.
class TransactionsView extends StatelessWidget {
  /// Creates the view.
  const TransactionsView({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionsCubit cubit,
    String id,
  ) => confirmAndRemove(
    context,
    title: t.transactions.title,
    message: t.transactions.deleteConfirm,
    onConfirm: () => cubit.remove(id),
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TransactionsCubit>();
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        return switch (state) {
          TransactionsLoading() => const LoadingShimmerList(),
          TransactionsError() => ErrorView(
            message: t.transactions.saveError,
          ),
          TransactionsLoaded(:final transactions) when transactions.isEmpty =>
            _EmptyState(
              onAdd: () => openTransactionForm(context, cubit, state),
            ),
          TransactionsLoaded() => _LoadedBody(
            state: state,
            onFilter: cubit.setInstitutionFilter,
            onTap: (tx) =>
                openTransactionForm(context, cubit, state, existing: tx),
            onDelete: (id) => _confirmDelete(context, cubit, id),
          ),
        };
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.onFilter,
    required this.onTap,
    required this.onDelete,
  });

  final TransactionsLoaded state;
  final void Function(String?) onFilter;
  final void Function(AssetTransaction) onTap;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    // Filtering by bank only makes sense with more than one bank.
    final showFilter = state.institutions.length > 1;
    final visible = state.visibleTransactions;
    return Column(
      children: [
        if (showFilter)
          _InstitutionFilterBar(
            institutions: state.institutions,
            selected: state.institutionFilter,
            onSelect: onFilter,
          ),
        Expanded(
          child: visible.isEmpty
              ? const _NoFilterResults()
              : _TransactionsList(
                  state: state,
                  onTap: onTap,
                  onDelete: onDelete,
                ),
        ),
      ],
    );
  }
}

class _InstitutionFilterBar extends StatelessWidget {
  const _InstitutionFilterBar({
    required this.institutions,
    required this.selected,
    required this.onSelect,
  });

  final List<Institution> institutions;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          InvestancoFilterChip(
            label: t.transactions.filterAll,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final institution in institutions) ...[
            const SizedBox(width: 8),
            InvestancoFilterChip(
              label: institution.name,
              selected: selected == institution.id,
              onTap: () => onSelect(institution.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.transactions.noFilterResults,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.appColors.onBackgroundLight,
          ),
        ),
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
    final transactions = state.visibleTransactions;

    return EntityListView(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
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
          const SizedBox(width: 8),
          EntityDeleteButton(onPressed: onDelete),
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
