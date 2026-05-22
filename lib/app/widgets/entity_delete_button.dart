import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// The trailing trash-can button shared by the institution, asset and
/// transaction list tiles.
class EntityDeleteButton extends StatelessWidget {
  /// Creates the button.
  const EntityDeleteButton({required this.onPressed, super.key});

  /// Tap handler.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: t.common.delete,
      icon: FaIcon(
        FontAwesomeIcons.trashCan,
        size: 16,
        color: context.appColors.onBackgroundLight,
      ),
      onPressed: onPressed,
    );
  }
}
