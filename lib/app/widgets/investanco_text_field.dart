import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thin wrapper over [TextFormField] that applies the app's input styling and
/// exposes the props the forms actually use. Mirrors financo's
/// `FinancoTextField`.
class InvestancoTextField extends StatelessWidget {
  /// Creates a text field.
  const InvestancoTextField({
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.maxLines = 1,
    this.hintText,
    this.helperText,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  /// Floating label text.
  final String label;

  /// Optional controller.
  final TextEditingController? controller;

  /// Optional validator.
  final String? Function(String?)? validator;

  /// Change callback.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field (keyboard done action).
  final ValueChanged<String>? onSubmitted;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Input formatters (e.g. digits only).
  final List<TextInputFormatter>? inputFormatters;

  /// Leading icon.
  final Widget? prefixIcon;

  /// Leading inline text (e.g. a currency symbol).
  final String? prefixText;

  /// Trailing icon.
  final Widget? suffixIcon;

  /// Trailing inline text (e.g. a unit).
  final String? suffixText;

  /// Max lines (set higher for notes).
  final int maxLines;

  /// Placeholder hint.
  final String? hintText;

  /// Helper text shown below the field.
  final String? helperText;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Auto-capitalization behaviour.
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
      ),
    );
  }
}
