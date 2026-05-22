import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_soft_icon_button.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// The trailing trash-can button shared by the institution, asset and
/// transaction list tiles — a neutral-tinted soft square so it reads as a
/// deliberate affordance without shouting on every row. See
/// [InvestancoSoftIconButton].
class EntityDeleteButton extends StatelessWidget {
  /// Creates the button.
  const EntityDeleteButton({required this.onPressed, super.key});

  /// Tap handler.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InvestancoSoftIconButton(
      icon: FontAwesomeIcons.trashCan,
      tooltip: t.common.delete,
      color: context.appColors.onBackgroundLight,
      onPressed: onPressed,
    );
  }
}
