import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// A compact, tappable soft squircle icon button: a tinted rounded square holding
/// a centered Font Awesome glyph, with an ink ripple. The premium counterpart to
/// a bare [IconButton] — used for app-bar actions (refresh) and list-row
/// affordances (delete, remove). [color] tints both the glyph and its
/// low-opacity background and defaults to the theme's primary.
///
/// Pass [busy] to swap the glyph for a spinner (e.g. while a refresh is in
/// flight); taps are ignored while busy or when [onPressed] is null.
///
/// Example:
/// ```dart
/// InvestancoSoftIconButton(
///   icon: FontAwesomeIcons.arrowsRotate,
///   tooltip: t.dashboard.refresh,
///   busy: isRefreshing,
///   onPressed: cubit.refresh,
/// )
/// ```
class InvestancoSoftIconButton extends StatelessWidget {
  /// Creates a soft icon button.
  const InvestancoSoftIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.busy = false,
    this.size = 40,
    this.iconSize = 16,
    super.key,
  });

  /// The glyph shown inside the square (replaced by a spinner while [busy]).
  final FaIconData icon;

  /// Tap handler; a null handler (or [busy]) renders the button disabled.
  final VoidCallback? onPressed;

  /// Tooltip / accessibility label.
  final String? tooltip;

  /// Tint for the glyph and background; defaults to `appColors.primary`.
  final Color? color;

  /// When true, shows a spinner and ignores taps (e.g. an in-flight refresh).
  final bool busy;

  /// Outer square side.
  final double size;

  /// Glyph (and spinner) side.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.appColors.primary;
    final enabled = !busy && onPressed != null;
    final radius = BorderRadius.circular(size * 0.3);

    final button = Material(
      color: tint.withValues(alpha: enabled ? 0.14 : 0.08),
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: busy
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tint,
                    ),
                  )
                : FaIcon(
                    icon,
                    size: iconSize,
                    color: enabled ? tint : tint.withValues(alpha: 0.5),
                  ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}
