import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Centered error state with a retry action. Mirrors financo's `ErrorView`.
class ErrorView extends StatelessWidget {
  /// Creates an error view.
  const ErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  /// User-facing error message.
  final String message;

  /// Retry handler.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 56,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: Text(t.common.retry),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
