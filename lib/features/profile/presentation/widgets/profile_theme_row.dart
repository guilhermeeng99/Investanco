import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_pill_toggle.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_segmented_row.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Theme picker row: a 3-way segmented toggle (System / Light / Dark) wired to
/// [ProfileCubit] (persists + applies live). Mirrors financo's `ProfileThemeRow`.
class ProfileThemeRow extends StatelessWidget {
  /// Creates the row.
  const ProfileThemeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, AppSettings>(
      builder: (context, settings) {
        return ProfileSegmentedRow<AppThemeMode>(
          icon: _iconFor(settings.themeMode, context),
          title: t.profile.theme,
          selected: settings.themeMode,
          onChanged: (mode) =>
              unawaited(context.read<ProfileCubit>().setThemeMode(mode)),
          options: [
            InvestancoPillToggleOption(
              value: AppThemeMode.light,
              label: t.profile.themeLight,
              icon: FontAwesomeIcons.sun,
            ),
            InvestancoPillToggleOption(
              value: AppThemeMode.dark,
              label: t.profile.themeDark,
              icon: FontAwesomeIcons.moon,
            ),
            InvestancoPillToggleOption(
              value: AppThemeMode.system,
              label: t.profile.themeSystem,
              icon: FontAwesomeIcons.mobileScreen,
            ),
          ],
        );
      },
    );
  }

  static FaIconData _iconFor(AppThemeMode mode, BuildContext context) {
    return switch (mode) {
      AppThemeMode.dark => FontAwesomeIcons.moon,
      AppThemeMode.light => FontAwesomeIcons.sun,
      AppThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? FontAwesomeIcons.moon
            : FontAwesomeIcons.sun,
    };
  }
}
