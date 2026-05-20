import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Uppercase, letter-spaced header used to separate logical groups in
/// long-scrolling pages. Mirrors financo's `FinancoSectionHeader`.
class InvestancoSectionHeader extends StatelessWidget {
  /// Creates a section header.
  const InvestancoSectionHeader({
    required this.title,
    this.count,
    this.accent,
    this.trailing,
    super.key,
  });

  /// Header text (rendered uppercase).
  final String title;

  /// Optional count badge.
  final int? count;

  /// Optional accent colour for the leading dot + count badge.
  final Color? accent;

  /// Optional trailing widget (e.g. a "see all" action).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dotColor = accent ?? colors.onBackgroundLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onBackgroundLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: context.textTheme.labelSmall?.copyWith(
                  color: dotColor,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
