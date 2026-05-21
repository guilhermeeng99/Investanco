import 'package:flutter/material.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Shows a cancel/confirm [AlertDialog] and resolves to true only when the user
/// taps the confirm action (false on cancel or dismiss). [confirmLabel] defaults
/// to the shared delete label.
///
/// Example:
/// ```dart
/// if (await showConfirmDialog(context, title: asset.ticker,
///     message: t.assets.deleteConfirm)) {
///   // delete
/// }
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? t.common.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
