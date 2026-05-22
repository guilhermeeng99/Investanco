import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_icon_disc.dart';
import 'package:investanco/app/widgets/investanco_pill_toggle.dart';
import 'package:investanco/core/extensions/context_extensions.dart';

/// A profile preference row: a leading [icon] disc + [title] above a segmented
/// [InvestancoPillToggle] of [options]. Shared by the language and theme
/// pickers, which differ only in their cubit, title and segments.
///
/// Example:
/// ```dart
/// ProfileSegmentedRow<AppThemeMode>(
///   icon: FontAwesomeIcons.moon,
///   title: t.profile.theme,
///   selected: settings.themeMode,
///   options: [...],
///   onChanged: cubit.setThemeMode,
/// );
/// ```
class ProfileSegmentedRow<T> extends StatelessWidget {
  /// Creates the row.
  const ProfileSegmentedRow({
    required this.icon,
    required this.title,
    required this.selected,
    required this.options,
    required this.onChanged,
    super.key,
  });

  /// Leading icon shown inside the tinted disc.
  final FaIconData icon;

  /// Row title.
  final String title;

  /// Currently selected segment value.
  final T selected;

  /// The segments to offer.
  final List<InvestancoPillToggleOption<T>> options;

  /// Selection callback.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              InvestancoIconDisc(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InvestancoPillToggle<T>(
            selected: selected,
            onChanged: onChanged,
            options: options,
          ),
        ],
      ),
    );
  }
}
