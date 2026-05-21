import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Small tinted pill with a coloured label and optional leading glyph, used for
/// inline tags (asset class, currency, operation, institution). The fill is the
/// label colour at low opacity so the chip stays legible on any surface.
///
/// Example:
/// ```dart
/// InvestancoChip(label: 'ETF (US)', color: assetKindColor(kind))
/// ```
class InvestancoChip extends StatelessWidget {
  /// Creates a chip.
  const InvestancoChip({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  /// Chip text.
  final String label;

  /// Drives both the label colour and the tinted background.
  final Color color;

  /// Optional leading glyph.
  final FaIconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            FaIcon(icon, size: 10, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
