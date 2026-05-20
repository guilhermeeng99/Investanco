import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/widgets/investanco_pill_toggle.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Theme picker row: a 3-way segmented toggle (System / Light / Dark) wired to
/// [ProfileCubit] (persists + applies live). Mirrors financo's `ProfileThemeRow`.
class ProfileThemeRow extends StatelessWidget {
  /// Creates the row.
  const ProfileThemeRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<ProfileCubit, AppSettings>(
      builder: (context, settings) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _IconDisc(icon: _iconFor(settings.themeMode, context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.profile.theme,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InvestancoPillToggle<AppThemeMode>(
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
              ),
            ],
          ),
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

class _IconDisc extends StatelessWidget {
  const _IconDisc({required this.icon});

  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: FaIcon(icon, size: 15, color: colors.primary)),
    );
  }
}
