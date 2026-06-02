import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/date_formatter.dart';
import 'package:investanco/core/format/number_format.dart';
import 'package:investanco/features/portfolio_import/domain/import_transactions_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_flow.dart';
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
    final popped = await commitImport(
      context,
      () => sl<ImportTransactionsCsvUseCase>().importRows([
        for (final r in _preview.rows) r.row,
      ]),
    );
    if (!popped && mounted) setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _preview.isEmpty;
    return ImportPreviewScaffold(
      title: t.importTransactions.previewTitle,
      subtitle: t.importTransactions.previewSubtitle,
      isEmpty: isEmpty,
      isImporting: _importing,
      canSubmit: _preview.canImport,
      submitLabel: isEmpty
          ? t.importCsv.previewNothingLeft
          : t.importTransactions.submit(count: _preview.rows.length),
      onSubmit: _import,
      body: _PreviewList(preview: _preview, onRemove: _removeRow),
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
    final unlinked = preview.unlinkedTickers;
    final mismatched = preview.institutionMismatchTickers;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: _SummaryCard(preview: preview)),
        ),
        if (missing.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _BlockingBanner(
                title: t.importTransactions.missingTitle,
                body: t.importTransactions.missingBody(
                  tickers: missing.join(', '),
                ),
              ),
            ),
          ),
        if (unlinked.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _BlockingBanner(
                title: t.importTransactions.unlinkedTitle,
                body: t.importTransactions.unlinkedBody(
                  tickers: unlinked.join(', '),
                ),
              ),
            ),
          ),
        if (mismatched.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _BlockingBanner(
                title: t.importTransactions.mismatchTitle,
                body: t.importTransactions.mismatchBody(
                  tickers: mismatched.join(', '),
                ),
              ),
            ),
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
                  icon: FontAwesomeIcons.triangleExclamation,
                  value: '${preview.rows.where((r) => !r.canImport).length}',
                  label: t.importTransactions.statBlocked,
                  color: colors.error,
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

/// Error banner listing rows blocked by missing or inconsistent references.
class _BlockingBanner extends StatelessWidget {
  const _BlockingBanner({required this.title, required this.body});

  final String title;
  final String body;

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
                  title,
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
            body,
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
          BrandAvatar(
            background: accent,
            icon: transactionKindIcon(row.operation),
          ),
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
                          color: entry.canImport
                              ? colors.onBackground
                              : colors.error,
                        ),
                      ),
                    ),
                    if (!entry.canImport) ...[
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
                      color: entry.institutionMatchesAsset
                          ? colors.neutral
                          : colors.error,
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
    return '${formatTrimmedDouble(row.quantity)} × $price  ·  $date';
  }
}
