import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/date_formatter.dart';
import 'package:investanco/features/portfolio_import/domain/import_transactions_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_dialog.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/import_preview_widgets.dart';
import 'package:investanco/features/transactions/domain/entities/asset_transaction.dart';
import 'package:investanco/features/transactions/presentation/transaction_labels.dart';
import 'package:investanco/features/transactions/presentation/transaction_visuals.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Review step before committing a transactions CSV import: a summary, a banner
/// for any rows whose asset isn't registered yet (which blocks import), and a
/// prunable per-row list. Confirming runs the import and pops the
/// [TransactionImportResult]. See `docs/specs/csv_import.md`.
class TransactionsImportPreviewPage extends StatefulWidget {
  /// Creates the page over an already-parsed [preview].
  const TransactionsImportPreviewPage({required this.preview, super.key});

  /// Route path (pushed onto the root navigator).
  static const String routePath = '/import/transactions/preview';

  /// Route name.
  static const String routeName = 'import-transactions-preview';

  /// The parsed import, from `ImportTransactionsCsvUseCase.previewRows`.
  final TransactionImportPreview preview;

  @override
  State<TransactionsImportPreviewPage> createState() =>
      _TransactionsImportPreviewPageState();
}

class _TransactionsImportPreviewPageState
    extends State<TransactionsImportPreviewPage> {
  late TransactionImportPreview _preview;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _preview = widget.preview;
  }

  void _removeRow(int index) =>
      setState(() => _preview = _preview.withoutRowAt(index));

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await sl<ImportTransactionsCsvUseCase>().importRows([
        for (final r in _preview.rows) r.row,
      ]);
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() => _importing = false);
          unawaited(showCsvImportErrorDialog(context, failure.message));
        },
        (tally) => context.pop(tally),
      );
    } on Exception {
      if (!mounted) return;
      setState(() => _importing = false);
      unawaited(showCsvImportErrorDialog(context, t.importCsv.genericError));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEmpty = _preview.isEmpty;
    return PopScope(
      canPop: !_importing,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: InvestancoAppBar(
          title: t.importTransactions.previewTitle,
          subtitle: t.importTransactions.previewSubtitle,
          showBack: true,
        ),
        body: Stack(
          children: [
            if (isEmpty)
              EmptyState(
                title: t.importCsv.previewEmptyTitle,
                message: t.importCsv.previewEmpty,
              )
            else
              _PreviewList(preview: _preview, onRemove: _removeRow),
            if (_importing) const ImportingOverlay(),
          ],
        ),
        bottomNavigationBar: InvestancoSubmitBar(
          label: isEmpty
              ? t.importCsv.previewNothingLeft
              : t.importTransactions.submit(count: _preview.rows.length),
          isLoading: _importing,
          isEnabled: _preview.canImport,
          onSubmit: _import,
        ),
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.preview, required this.onRemove});

  final TransactionImportPreview preview;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final rows = preview.rows;
    final missing = preview.missingTickers;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: _SummaryCard(preview: preview)),
        ),
        if (missing.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(child: _MissingBanner(tickers: missing)),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: InvestancoSectionHeader(
              title: t.importCsv.previewItemsHeader,
              count: rows.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionRowTile(
                entry: rows[i],
                onRemove: () => onRemove(i),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.preview});

  final TransactionImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InvestancoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ImportSummaryStat(
                  icon: FontAwesomeIcons.rightLeft,
                  value: '${preview.transactionCount}',
                  label: t.importTransactions.statTransactions,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: ImportSummaryStat(
                  icon: FontAwesomeIcons.buildingColumns,
                  value: '${preview.newInstitutionCount}',
                  label: t.importTransactions.statNewInstitutions,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: colors.surfaceVariant),
          const SizedBox(height: 12),
          ImportSummaryNote(text: t.importTransactions.reuseNote),
        ],
      ),
    );
  }
}

/// Error banner listing tickers whose asset isn't registered yet; import is
/// blocked until they're removed or the assets are imported first.
class _MissingBanner extends StatelessWidget {
  const _MissingBanner({required this.tickers});

  final List<String> tickers;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 14,
                color: colors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.importTransactions.missingTitle,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.importTransactions.missingBody(tickers: tickers.join(', ')),
            style: context.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
      ),
    );
  }
}

class _TransactionRowTile extends StatelessWidget {
  const _TransactionRowTile({required this.entry, required this.onRemove});

  final TransactionImportPreviewRow entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final row = entry.row;
    final accent = transactionKindColor(row.operation, colors);

    return InvestancoCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          BrandAvatar(background: accent, icon: transactionKindIcon(row.operation)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.ticker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          // Dim tickers whose asset is missing — they block import.
                          color: entry.assetExists
                              ? colors.onBackground
                              : colors.error,
                        ),
                      ),
                    ),
                    if (!entry.assetExists) ...[
                      const SizedBox(width: 6),
                      FaIcon(
                        FontAwesomeIcons.circleExclamation,
                        size: 12,
                        color: colors.error,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InvestancoChip(
                      label: transactionKindLabel(row.operation),
                      color: accent,
                      icon: transactionKindIcon(row.operation),
                    ),
                    InvestancoChip(
                      label: row.institutionName,
                      color: entry.institutionIsNew
                          ? colors.positive
                          : colors.neutral,
                      icon: FontAwesomeIcons.buildingColumns,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _caption(row),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.onBackgroundLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ImportRemoveButton(onPressed: onRemove),
        ],
      ),
    );
  }

  /// `qty × price · date` for buys/sells; `amount · date` for dividends. Raw
  /// file values (currency is resolved from the asset only at import time).
  String _caption(TransactionImportRow row) {
    final date = formatShortDate(row.date);
    if (row.operation == TransactionKind.dividend) {
      return '${(row.amountMajor ?? 0).toStringAsFixed(2)}  ·  $date';
    }
    final price = row.unitPriceMajor.toStringAsFixed(2);
    return '${_quantity(row.quantity)} × $price  ·  $date';
  }

  String _quantity(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : '$q';
}
