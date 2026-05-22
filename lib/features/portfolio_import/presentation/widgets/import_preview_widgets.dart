import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// The shared shell for a CSV import preview page: a back-titled app bar, the
/// review [body] (or an empty state), a blocking overlay while importing, and a
/// submit bar. Assets and transactions differ only in titles, the body and the
/// submit label/enablement. See `docs/specs/csv_import.md`.
class ImportPreviewScaffold extends StatelessWidget {
  /// Creates the scaffold.
  const ImportPreviewScaffold({
    required this.title,
    required this.subtitle,
    required this.isEmpty,
    required this.isImporting,
    required this.canSubmit,
    required this.submitLabel,
    required this.body,
    required this.onSubmit,
    super.key,
  });

  /// App-bar title.
  final String title;

  /// App-bar subtitle.
  final String subtitle;

  /// Whether the review list is empty (shows the empty state instead of [body]).
  final bool isEmpty;

  /// Whether an import is running (blocks pop + shows the overlay).
  final bool isImporting;

  /// Whether the submit button is enabled.
  final bool canSubmit;

  /// Submit-button label.
  final String submitLabel;

  /// The review list, shown when not [isEmpty].
  final Widget body;

  /// Submit handler.
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isImporting,
      child: Scaffold(
        backgroundColor: context.appColors.background,
        appBar: InvestancoAppBar(
          title: title,
          subtitle: subtitle,
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
              body,
            if (isImporting) const ImportingOverlay(),
          ],
        ),
        bottomNavigationBar: InvestancoSubmitBar(
          label: submitLabel,
          isLoading: isImporting,
          isEnabled: canSubmit,
          onSubmit: onSubmit,
        ),
      ),
    );
  }
}

/// One headline figure in an import summary card (icon badge, value, label and
/// an optional muted caption). Shared by the asset and transaction previews.
class ImportSummaryStat extends StatelessWidget {
  /// Creates a summary stat.
  const ImportSummaryStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.caption,
    super.key,
  });

  /// Glyph in the tinted badge.
  final FaIconData icon;

  /// Big headline value.
  final String value;

  /// Muted label under the value.
  final String label;

  /// Accent for the badge + icon.
  final Color color;

  /// Optional secondary line (e.g. `+2 reused`).
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: FaIcon(icon, size: 15, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: context.textTheme.headlineSmall?.copyWith(
            color: colors.onBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.onBackgroundLight,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onBackgroundLight.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Muted info row under the summary stats explaining the reuse rule.
class ImportSummaryNote extends StatelessWidget {
  /// Creates a note row.
  const ImportSummaryNote({required this.text, super.key});

  /// The explanatory text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(
          FontAwesomeIcons.circleInfo,
          size: 13,
          color: colors.onBackgroundLight,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onBackgroundLight,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Filled positive badge marking an item that doesn't exist yet.
class ImportNewBadge extends StatelessWidget {
  /// Creates the badge.
  const ImportNewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.positive,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        t.importCsv.previewBadgeNew,
        style: context.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// Error-tinted soft-square button to drop a row from the import.
class ImportRemoveButton extends StatelessWidget {
  /// Creates the remove button.
  const ImportRemoveButton({required this.onPressed, super.key});

  /// Tap handler.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InvestancoSoftIconButton(
      icon: FontAwesomeIcons.trashCan,
      tooltip: t.importCsv.previewRemoveRow,
      color: context.appColors.error,
      onPressed: onPressed,
      size: 36,
      iconSize: 13,
    );
  }
}

/// Blocking scrim shown while an import runs, so the list can't be edited
/// mid-flight.
class ImportingOverlay extends StatelessWidget {
  /// Creates the overlay.
  const ImportingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.importCsv.previewImporting,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
