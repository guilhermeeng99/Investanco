import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_dialog.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Shows a destructive confirm dialog (the shared delete prompt) and resolves
/// to true only when the user taps the confirm action (false on cancel or
/// dismiss). Thin wrapper over [showInvestancoConfirmDialog] so every delete
/// across the app shares the same design-system look: a tinted warning badge
/// and an error-accent confirm button. [confirmLabel] defaults to the shared
/// delete label; pass [destructive]: false for a neutral confirm.
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
  FaIconData? icon,
  bool destructive = true,
}) {
  return showInvestancoConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel ?? t.common.delete,
    icon: icon ?? FontAwesomeIcons.trashCan,
    destructive: destructive,
  );
}
