import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Sticky bottom bar carrying a form's primary submit action. Use it as
/// `Scaffold.bottomNavigationBar` (or the last child of a sheet) so the
/// keyboard pushes it up instead of covering it. Mirrors financo's
/// `FinancoSubmitBar`.
class InvestancoSubmitBar extends StatelessWidget {
  /// Creates a submit bar.
  const InvestancoSubmitBar({
    required this.label,
    required this.onSubmit,
    this.isLoading = false,
    this.isEnabled = true,
    super.key,
  });

  /// Button label.
  final String label;

  /// Submit handler.
  final VoidCallback onSubmit;

  /// When true, shows a spinner and blocks taps.
  final bool isLoading;

  /// When false, the button is disabled.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canPress = isEnabled && !isLoading;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.surfaceVariant)),
      ),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: canPress ? onSubmit : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            disabledBackgroundColor: colors.primary.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
