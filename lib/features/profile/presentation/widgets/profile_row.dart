import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// One row inside a `ProfileSection`: icon disc, title, optional subtitle, and a
/// trailing widget (chevron by default). Mirrors financo's `ProfileRow`.
///
/// [onTap] is nullable so a row can be a read-only display (e.g. base currency).
/// [accent] tints the disc; [destructive] paints the icon + title in the error
/// colour for risky actions.
class ProfileRow extends StatelessWidget {
  /// Creates a row.
  const ProfileRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.accent,
    this.trailing,
    this.destructive = false,
    super.key,
  });

  /// Leading icon.
  final FaIconData icon;

  /// Row title.
  final String title;

  /// Optional supporting line.
  final String? subtitle;

  /// Tap handler, or null for a read-only row.
  final VoidCallback? onTap;

  /// Icon-disc tint (defaults to primary).
  final Color? accent;

  /// Trailing widget (defaults to a chevron when [onTap] is set).
  final Widget? trailing;

  /// Paints icon + title in the error colour.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final iconColor = destructive ? colors.error : (accent ?? colors.primary);
    final titleColor = destructive ? colors.error : colors.onBackground;
    final trailingWidget = trailing ??
        (onTap != null
            ? FaIcon(
                FontAwesomeIcons.chevronRight,
                size: 12,
                color: colors.onBackgroundLight,
              )
            : null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _IconDisc(icon: icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onBackgroundLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 8),
                trailingWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.icon, required this.color});

  final FaIconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: FaIcon(icon, size: 15, color: color)),
    );
  }
}
