import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Centered empty-state placeholder: an illustrative icon, a message and an
/// optional call-to-action button. Mirrors financo's `EmptyState`.
class EmptyState extends StatelessWidget {
  /// Creates an empty state.
  const EmptyState({
    required this.message,
    this.icon = FontAwesomeIcons.boxOpen,
    this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Primary explanatory message.
  final String message;

  /// Optional short heading shown above [message].
  final String? title;

  /// Icon shown above the text.
  final FaIconData icon;

  /// Optional CTA label (renders a button when [onAction] is also set).
  final String? actionLabel;

  /// Optional CTA handler.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 40, color: colors.primary),
            ),
            const SizedBox(height: 20),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.onBackgroundLight,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
