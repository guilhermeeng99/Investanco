import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Card-style wrapper that groups related form fields under an uppercase
/// label, so a long form scans as distinct sections instead of a flat stack
/// of inputs. Mirrors financo's `FinancoFormSection`.
class InvestancoFormSection extends StatelessWidget {
  /// Creates a form section.
  const InvestancoFormSection({
    required this.label,
    required this.children,
    this.spacing = 12,
    super.key,
  });

  /// Uppercase section label.
  final String label;

  /// Section fields. Vertical [spacing] is inserted between each.
  final List<Widget> children;

  /// Gap inserted between [children].
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            label.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onBackgroundLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spaced(children),
          ),
        ),
      ],
    );
  }

  List<Widget> _spaced(List<Widget> items) {
    if (items.length < 2) return items;
    return [
      for (var i = 0; i < items.length; i++) ...[
        items[i],
        if (i < items.length - 1) SizedBox(height: spacing),
      ],
    ];
  }
}
