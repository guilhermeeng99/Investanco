import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// A 36×36 rounded disc holding a tinted Font Awesome [icon] — the leading
/// affordance shared by profile rows, the language/theme pickers and section
/// headers. [color] tints both the glyph and its 14%-opacity background and
/// defaults to the theme's primary.
///
/// Example: `InvestancoIconDisc(icon: FontAwesomeIcons.gear)`.
class InvestancoIconDisc extends StatelessWidget {
  /// Creates an icon disc.
  const InvestancoIconDisc({required this.icon, this.color, super.key});

  /// The glyph shown inside the disc.
  final FaIconData icon;

  /// Tint for the glyph and background; defaults to `appColors.primary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.appColors.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: FaIcon(icon, size: 15, color: tint)),
    );
  }
}
