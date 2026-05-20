import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Compact label-over-value cell used inside the portfolio summary card to
/// show secondary figures (Invested, Day change) side by side. Keeps the
/// label muted and lets [value] (usually a `MoneyText` / `SignedAmount`)
/// carry the emphasis.
class MetricTile extends StatelessWidget {
  /// Creates a metric tile.
  const MetricTile({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    super.key,
  });

  /// Muted caption above the value.
  final String label;

  /// The value widget (e.g. `MoneyText`, `SignedAmount`).
  final Widget value;

  /// Horizontal alignment of the label/value column.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.onBackgroundLight,
          ),
        ),
        const SizedBox(height: 6),
        value,
      ],
    );
  }
}
