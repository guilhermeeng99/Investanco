import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Tap-to-open selector row: optional leading widget, label-on-top with the
/// chosen value below, trailing chevron. Used by the institution/asset
/// pickers in the transaction form. Mirrors financo's `FinancoPickerField`.
class InvestancoPickerField extends StatelessWidget {
  /// Creates a picker field.
  const InvestancoPickerField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.leading,
    this.isError = false,
    super.key,
  });

  /// Field label.
  final String label;

  /// Currently selected display value, or null when nothing is picked.
  final String? value;

  /// Placeholder shown when [value] is null.
  final String placeholder;

  /// Tap handler that opens the selection sheet.
  final VoidCallback onTap;

  /// Optional leading widget (e.g. an avatar).
  final Widget? leading;

  /// When true, the value renders in the error colour.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasValue = value != null && value!.isNotEmpty;
    final valueColor = isError
        ? colors.error
        : hasValue
            ? colors.onBackground
            : colors.onBackgroundLight;
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.onBackgroundLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasValue ? value! : placeholder,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 11,
                color: colors.onBackgroundLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
