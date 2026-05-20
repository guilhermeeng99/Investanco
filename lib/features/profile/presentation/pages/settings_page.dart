import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/gen/strings.g.dart';

/// User preferences: theme, brapi token, base currency. See
/// `docs/specs/profile.md`.
class SettingsPage extends StatelessWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  /// Route path.
  static const String routePath = '/settings';

  /// Route name.
  static const String routeName = 'settings';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) {
        final cubit = sl<ProfileCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  String _themeLabel(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => t.settings.themeSystem,
        AppThemeMode.light => t.settings.themeLight,
        AppThemeMode.dark => t.settings.themeDark,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.title)),
      body: BlocBuilder<ProfileCubit, AppSettings>(
        builder: (context, settings) {
          final cubit = context.read<ProfileCubit>();
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(t.settings.theme),
                trailing: DropdownButton<AppThemeMode>(
                  value: settings.themeMode,
                  items: [
                    for (final mode in AppThemeMode.values)
                      DropdownMenuItem(
                        value: mode,
                        child: Text(_themeLabel(mode)),
                      ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) unawaited(cubit.setThemeMode(mode));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextFormField(
                  initialValue: settings.brapiToken ?? '',
                  decoration: InputDecoration(
                    labelText: t.settings.brapiToken,
                    helperText: t.settings.brapiTokenHelp,
                  ),
                  onFieldSubmitted: (value) =>
                      unawaited(cubit.setBrapiToken(value)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(t.settings.baseCurrency),
                trailing: Text(settings.baseCurrency.code),
              ),
            ],
          );
        },
      ),
    );
  }
}
