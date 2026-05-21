import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_dialog.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Type-to-confirm dialog for wiping the signed-in user's data. Resolves to
/// `true` only when the user typed their own email (case-insensitive) and
/// tapped Delete. Falls back to `false` on cancel / dismiss.
///
/// Mirrors financo's clear-data flow: a destructive, irreversible action must
/// require explicit confirmation, not a single careless tap. Built on
/// [InvestancoDialog] so it shares the app's dialog look (warning badge,
/// centred copy, destructive action button).
Future<bool> showClearAccountDataDialog(
  BuildContext context, {
  required String email,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ClearAccountDataDialog(email: email),
  );
  return result ?? false;
}

class _ClearAccountDataDialog extends StatefulWidget {
  const _ClearAccountDataDialog({required this.email});

  final String email;

  @override
  State<_ClearAccountDataDialog> createState() =>
      _ClearAccountDataDialogState();
}

class _ClearAccountDataDialogState extends State<_ClearAccountDataDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final next =
        _controller.text.trim().toLowerCase() == widget.email.toLowerCase();
    if (next != _matches) setState(() => _matches = next);
  }

  @override
  Widget build(BuildContext context) {
    return InvestancoDialog(
      icon: FontAwesomeIcons.triangleExclamation,
      iconColor: context.appColors.error,
      title: t.profile.clearDataConfirmHeadline,
      message: t.profile.clearDataConfirmBody,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EmailChip(email: widget.email),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: t.profile.clearDataConfirmField,
            ),
            onSubmitted: (_) {
              if (_matches) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      actions: [
        InvestancoDialogAction(
          label: t.common.cancel,
          onPressed: () => Navigator.pop(context, false),
        ),
        InvestancoDialogAction(
          label: t.common.delete,
          kind: InvestancoDialogActionKind.destructive,
          // Disabled until the typed email matches — gates the irreversible
          // wipe behind an explicit, deliberate confirmation.
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
        ),
      ],
    );
  }
}

/// Read-only chip echoing the email the user must type to confirm.
class _EmailChip extends StatelessWidget {
  const _EmailChip({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        email,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
