import 'package:flutter/material.dart';

/// Full-width primary/secondary action button with a built-in loading
/// spinner and optional leading icon. Mirrors financo's `FinancoButton`.
class InvestancoButton extends StatelessWidget {
  /// Creates a button. Set [isOutlined] for the secondary style.
  const InvestancoButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    super.key,
  });

  /// Button label.
  final String label;

  /// Tap handler; pass null to disable.
  final VoidCallback? onPressed;

  /// When true, shows a spinner and blocks taps.
  final bool isLoading;

  /// When true, renders the outlined (secondary) variant.
  final bool isOutlined;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
