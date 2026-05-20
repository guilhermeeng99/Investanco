import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// One selectable row in [showOptionPicker].
class OptionPickerItem<T> {
  /// Creates an item.
  const OptionPickerItem({
    required this.value,
    required this.label,
    this.leading,
  });

  /// The value returned when picked.
  final T value;

  /// Display label.
  final String label;

  /// Optional leading widget (e.g. an avatar or icon).
  final Widget? leading;
}

/// Opens a modal bottom sheet listing [items] and returns the chosen value
/// (or null if dismissed). The current [selected] row is highlighted with a
/// check. A shared replacement for raw `DropdownButtonFormField`s so every
/// form picks options with the same friendly, large-target sheet.
Future<T?> showOptionPicker<T>(
  BuildContext context, {
  required String title,
  required List<OptionPickerItem<T>> items,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final colors = sheetContext.appColors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Text(title, style: sheetContext.textTheme.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in items)
                      ListTile(
                        leading: item.leading,
                        title: Text(item.label),
                        trailing: item.value == selected
                            ? FaIcon(
                                FontAwesomeIcons.check,
                                size: 16,
                                color: colors.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(item.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
