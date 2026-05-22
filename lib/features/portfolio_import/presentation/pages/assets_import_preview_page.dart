import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/format/initials.dart';
import 'package:investanco/features/assets/presentation/asset_labels.dart';
import 'package:investanco/features/assets/presentation/asset_visuals.dart';
import 'package:investanco/features/portfolio_import/domain/import_assets_csv_usecase.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/csv_import_flow.dart';
import 'package:investanco/features/portfolio_import/presentation/widgets/import_preview_widgets.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Review step before committing an assets CSV import: a summary of new vs.
/// reused assets and a per-row list the user can prune. Confirming runs the
/// import and pops the [AssetImportResult]. See `docs/specs/csv_import.md`.
class AssetsImportPreviewPage extends StatefulWidget {
  /// Creates the page over an already-parsed [preview].
  const AssetsImportPreviewPage({required this.preview, super.key});

  /// Route path (pushed onto the root navigator).
  static const String routePath = '/import/assets/preview';

  /// Route name.
  static const String routeName = 'import-assets-preview';

  /// The parsed import, from `ImportAssetsCsvUseCase.previewRows`.
  final AssetImportPreview preview;

  @override
  State<AssetsImportPreviewPage> createState() =>
      _AssetsImportPreviewPageState();
}

class _AssetsImportPreviewPageState extends State<AssetsImportPreviewPage> {
  late AssetImportPreview _preview;
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
      () => sl<ImportAssetsCsvUseCase>().importRows([
        for (final r in _preview.rows) r.row,
      ]),
    );
    if (!popped && mounted) setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _preview.isEmpty;
    return ImportPreviewScaffold(
      title: t.importAssets.previewTitle,
      subtitle: t.importAssets.previewSubtitle,
      isEmpty: isEmpty,
      isImporting: _importing,
      canSubmit: !isEmpty,
      submitLabel: isEmpty
          ? t.importCsv.previewNothingLeft
          : t.importAssets.submit(count: _preview.rows.length),
      onSubmit: _import,
      body: _PreviewList(preview: _preview, onRemove: _removeRow),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.preview, required this.onRemove});

  final AssetImportPreview preview;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final rows = preview.rows;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: _SummaryCard(preview: preview)),
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
              child: _AssetRowTile(entry: rows[i], onRemove: () => onRemove(i)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.preview});

  final AssetImportPreview preview;

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
                  icon: FontAwesomeIcons.coins,
                  value: '${preview.rows.length}',
                  label: t.importCsv.previewItemsHeader,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: ImportSummaryStat(
                  icon: FontAwesomeIcons.plus,
                  value: '${preview.newCount}',
                  label: t.importAssets.statNew,
                  color: colors.positive,
                  caption: preview.reusedCount > 0
                      ? t.importCsv.previewReusedCount(
                          count: preview.reusedCount,
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: colors.surfaceVariant),
          const SizedBox(height: 12),
          ImportSummaryNote(text: t.importAssets.reuseNote),
        ],
      ),
    );
  }
}

class _AssetRowTile extends StatelessWidget {
  const _AssetRowTile({required this.entry, required this.onRemove});

  final AssetImportPreviewRow entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final row = entry.row;
    final showName = row.name.toUpperCase() != row.ticker.toUpperCase();

    return InvestancoCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          BrandAvatar(
            background: assetKindColor(row.kind),
            initials: tickerInitials(row.ticker),
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
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                    if (entry.isNew) ...[
                      const SizedBox(width: 6),
                      const ImportNewBadge(),
                    ],
                  ],
                ),
                if (showName) ...[
                  const SizedBox(height: 2),
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.onBackgroundLight,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InvestancoChip(
                      label: assetKindLabel(row.kind),
                      color: assetKindColor(row.kind),
                    ),
                    InvestancoChip(
                      label: row.currency.code,
                      color: colors.neutral,
                    ),
                  ],
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
}
