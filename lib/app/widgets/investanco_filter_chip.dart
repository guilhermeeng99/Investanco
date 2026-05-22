import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// A standalone selectable pill for horizontal filter bars. Selected pills fill
/// with a brand tint and brand-coloured text; unselected ones use the muted
/// surface. Unlike `InvestancoPillToggle` (one widget for a fixed segment set),
/// each value is its own chip, so the bar can scroll an arbitrary list.
///
/// Example:
/// ```dart
/// InvestancoFilterChip(
///   label: 'Avenue',
///   selected: filter == 'avenue',
///   onTap: () => cubit.setInstitutionFilter('avenue'),
/// )
/// ```
class InvestancoFilterChip extends StatelessWidget {
  /// Creates a filter chip.
  const InvestancoFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Chip text.
  final String label;

  /// Whether this chip is the active filter.
  final bool selected;

  /// Tap callback (apply or clear this filter).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = selected ? colors.primary : colors.onBackgroundLight;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.12)
          : colors.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
