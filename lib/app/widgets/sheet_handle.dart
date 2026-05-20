import 'package:flutter/material.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// Small grab handle shown centered at the top of a modal bottom sheet, so
/// every form sheet reads as draggable and shares one look.
class SheetHandle extends StatelessWidget {
  /// Creates a sheet handle.
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.appColors.surfaceVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
