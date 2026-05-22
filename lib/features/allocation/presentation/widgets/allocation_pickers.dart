import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/allocation/presentation/allocation_visuals.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Modal grid to pick an allocation icon key. Returns the key, or null.
Future<String?> showAllocationIconPicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) {
      final colors = ctx.appColors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.allocation.classIcon, style: ctx.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in allocationIcons.entries)
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(entry.key),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          shape: BoxShape.circle,
                          border: entry.key == selected
                              ? Border.all(color: colors.primary, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: FaIcon(entry.value,
                              size: 20, color: colors.onBackground),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Modal grid to pick an allocation color (ARGB int). Returns the value, or null.
Future<int?> showAllocationColorPicker(
  BuildContext context, {
  required int selected,
}) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (ctx) {
      final colors = ctx.appColors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.allocation.classColor, style: ctx.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final value in allocationPalette)
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(value),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Color(value),
                          shape: BoxShape.circle,
                          border: value == selected
                              ? Border.all(color: colors.onBackground, width: 3)
                              : null,
                        ),
                        child: value == selected
                            ? const Center(
                                child: FaIcon(FontAwesomeIcons.check,
                                    size: 18, color: Colors.white),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
