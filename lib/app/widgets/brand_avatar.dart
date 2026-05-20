import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Circular brand disc filled with [background], showing either short
/// [initials] or an [icon]. Foreground contrast is derived from background
/// luminance, mirroring financo's `BankAvatar` approach so light brand
/// colours get dark glyphs and vice versa.
///
/// Features compute the colour + initials (e.g. asset ticker, institution
/// name); this widget owns only the presentation.
class BrandAvatar extends StatelessWidget {
  /// Creates an avatar from [initials].
  const BrandAvatar({
    required this.background,
    this.initials,
    this.icon,
    this.size = 44,
    super.key,
  }) : assert(
          initials != null || icon != null,
          'Provide either initials or an icon',
        );

  /// Disc fill colour.
  final Color background;

  /// Short text (1 to 4 chars); rendered when [icon] is null.
  final String? initials;

  /// Glyph rendered when [initials] is null.
  final FaIconData? icon;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final foreground =
        background.computeLuminance() > 0.55 ? Colors.black : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: icon != null
          ? FaIcon(icon, size: size * 0.42, color: foreground)
          : Text(
              initials!,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: _fontSize(initials!, size),
              ),
            ),
    );
  }

  /// Shrink the text as it grows so 4-char tickers still fit the disc.
  double _fontSize(String text, double size) {
    final length = text.length;
    if (length <= 2) return size * 0.40;
    if (length == 3) return size * 0.32;
    return size * 0.26;
  }
}
