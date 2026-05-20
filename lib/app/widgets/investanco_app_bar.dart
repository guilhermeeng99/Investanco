import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Standard app bar: large left-aligned title, optional actions and an
/// optional back button. Mirrors financo's `FinancoAppBar`, with the title
/// styled by the headline scale so top-level pages read as confident headers.
class InvestancoAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the app bar.
  const InvestancoAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    super.key,
  });

  /// Title text.
  final String title;

  /// Trailing actions (icons, menus).
  final List<Widget>? actions;

  /// Custom leading widget (ignored when [showBack] is true).
  final Widget? leading;

  /// When true, renders a back chevron that pops the route.
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: context.textTheme.headlineSmall),
      actions: actions,
      leading: showBack
          ? IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
              onPressed: () => Navigator.of(context).pop(),
            )
          : leading,
    );
  }
}
