import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Premium, iOS-style large-title app bar. The title is left-aligned and bold;
/// the bar blends with the scaffold background (no surface contrast, no shadow,
/// no scroll-under tint) so it reads as part of the page. Mirrors financo's
/// `FinancoLargeAppBar`.
///
/// Pass `showBack: true` on sub-pages for a soft circular back chevron while
/// keeping the large-title look.
class InvestancoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the app bar.
  const InvestancoAppBar({
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBack = false,
    super.key,
  });

  /// Title text (large, bold).
  final String title;

  /// Optional supporting line under the title.
  final String? subtitle;

  /// Trailing actions (icons, menus).
  final List<Widget>? actions;

  /// Custom leading widget (ignored when [showBack] is true).
  final Widget? leading;

  /// When true, renders a soft circular back chip that pops the route.
  final bool showBack;

  double get _height => subtitle != null ? 88 : 72;

  @override
  Size get preferredSize => Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.background,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack ? const _BackChip() : leading,
      leadingWidth: showBack ? 56 : null,
      titleSpacing: showBack ? 4 : 20,
      toolbarHeight: _height,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: context.textTheme.headlineSmall?.copyWith(
              color: colors.onBackground,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onBackgroundLight,
              ),
            ),
          ],
        ],
      ),
      // Inset trailing actions from the screen edge so they align with the
      // content gutter instead of hugging the corner on wide layouts.
      actions: actions == null ? null : [...actions!, const SizedBox(width: 12)],
    );
  }
}

/// Soft circular back chevron used on sub-pages.
class _BackChip extends StatelessWidget {
  const _BackChip();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Material(
          color: colors.surfaceVariant,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.chevronLeft,
                  size: 13,
                  color: colors.onBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
