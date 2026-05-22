import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/confirm_dialog.dart';
import 'package:investanco/core/error/failures.dart';

/// Confirms a destructive delete via [showConfirmDialog], then runs [onConfirm].
/// When it returns an [InUseFailure] and [inUseError] is set, shows that message
/// in a snackbar (records referenced by others can't be deleted). Shared by the
/// institution, asset and transaction list pages, which differ only in their
/// labels and cubit.
Future<void> confirmAndRemove(
  BuildContext context, {
  required String title,
  required String message,
  required Future<Failure?> Function() onConfirm,
  String? inUseError,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: title,
    message: message,
  );
  if (!confirmed || !context.mounted) return;

  final failure = await onConfirm();
  if (failure is InUseFailure && inUseError != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(inUseError)),
    );
  }
}
