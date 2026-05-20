import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// One option of an [InvestancoPillToggle].
class InvestancoPillToggleOption<T> {
  /// Creates an option.
  const InvestancoPillToggleOption({
    required this.value,
    required this.label,
    this.icon,
    this.accent,
  });

  /// The value selected when this segment is tapped.
  final T value;

  /// Segment label.
  final String label;

  /// Optional leading icon.
  final FaIconData? icon;

  /// Optional accent applied to the selected foreground (e.g. buy=green).
  final Color? accent;
}

/// Custom segmented pill toggle with large tap targets and a soft animated
/// selection. Mirrors financo's `FinancoPillToggle`; used for the theme
/// selector and the transaction kind (buy/sell/dividend) switch.
class InvestancoPillToggle<T> extends StatelessWidget {
  /// Creates a pill toggle.
  const InvestancoPillToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.disabled = false,
    super.key,
  });

  /// The segments to render.
  final List<InvestancoPillToggleOption<T>> options;

  /// Currently selected value.
  final T selected;

  /// Selection callback.
  final ValueChanged<T> onChanged;

  /// When true, the toggle is visually muted and taps no-op.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _Segment<T>(
                option: option,
                isSelected: option.value == selected,
                disabled: disabled,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.disabled,
    required this.onTap,
  });

  final InvestancoPillToggleOption<T> option;
  final bool isSelected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = isSelected
        ? (option.accent ?? colors.onBackground)
        : colors.onBackgroundLight;
    return Opacity(
      opacity: disabled && !isSelected ? 0.5 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (option.icon != null) ...[
                    FaIcon(option.icon, size: 13, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
