import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/lifted_fab.dart';

/// Stacked floating actions used on the Assets and Transactions pages: a small
/// **import** button sitting above the primary **add** button. Mirrors financo's
/// add + CSV-import affordance.
///
/// [heroPrefix] must be unique per page — the shell keeps every tab's navigator
/// alive at once, so two stacks share a `Navigator` and would clash hero tags
/// otherwise.
class ImportAddFab extends StatelessWidget {
  /// Creates the stack.
  const ImportAddFab({
    required this.heroPrefix,
    required this.onAdd,
    required this.onImport,
    required this.addTooltip,
    required this.importTooltip,
    super.key,
  });

  /// Page-unique hero-tag prefix (e.g. `assets`, `transactions`).
  final String heroPrefix;

  /// Tapped the large primary button.
  final VoidCallback onAdd;

  /// Tapped the small import button.
  final VoidCallback onImport;

  /// Tooltip / a11y label for the add button.
  final String addTooltip;

  /// Tooltip / a11y label for the import button.
  final String importTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: '${heroPrefix}_import_fab',
          tooltip: importTooltip,
          onPressed: onImport,
          child: const FaIcon(FontAwesomeIcons.fileArrowUp, size: 14),
        ),
        const SizedBox(height: 12),
        LiftedFab(
          child: FloatingActionButton(
            heroTag: '${heroPrefix}_add_fab',
            tooltip: addTooltip,
            onPressed: onAdd,
            child: const FaIcon(FontAwesomeIcons.plus, size: 18),
          ),
        ),
      ],
    );
  }
}
