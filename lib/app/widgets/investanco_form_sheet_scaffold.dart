import 'package:flutter/material.dart';
import 'package:investanco/app/widgets/investanco_button.dart';
import 'package:investanco/app/widgets/sheet_handle.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/error/validation_message.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Shared scaffold for the add/edit bottom-sheet forms (assets, institutions,
/// transactions). Owns the keyboard-inset padding, scrolling [Form], handle,
/// title, the Save button and the submit flow (validate → persist → show the
/// error snackbar or pop), so each feature sheet supplies only its [children]
/// fields and an [onSubmit] that persists and returns a [Failure] — or null on
/// success.
class InvestancoFormSheetScaffold extends StatefulWidget {
  /// Creates the scaffold.
  const InvestancoFormSheetScaffold({
    required this.formKey,
    required this.title,
    required this.onSubmit,
    required this.errorText,
    required this.children,
    super.key,
  });

  /// Key of the wrapped [Form]; validated before [onSubmit] runs.
  final GlobalKey<FormState> formKey;

  /// Sheet title (e.g. "Add asset").
  final String title;

  /// Persists the form; returns a [Failure] to surface, or null on success.
  final Future<Failure?> Function() onSubmit;

  /// Snackbar message shown when [onSubmit] returns a failure.
  final String errorText;

  /// The form fields, rendered between the title and the Save button.
  final List<Widget> children;

  @override
  State<InvestancoFormSheetScaffold> createState() =>
      _InvestancoFormSheetScaffoldState();
}

class _InvestancoFormSheetScaffoldState
    extends State<InvestancoFormSheetScaffold> {
  bool _saving = false;

  Future<void> _submit() async {
    if (!(widget.formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final failure = await widget.onSubmit();
    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      final message =
          (failure is ValidationFailure ? validationMessage(failure) : null) ??
              widget.errorText;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              Text(widget.title, style: context.textTheme.titleLarge),
              const SizedBox(height: 20),
              ...widget.children,
              const SizedBox(height: 24),
              InvestancoButton(
                label: t.common.save,
                isLoading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
