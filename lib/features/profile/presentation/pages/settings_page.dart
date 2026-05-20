import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// User preferences: theme, language, market-data tokens, base currency. See
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InvestancoAppBar(title: t.settings.title),
      body: BlocBuilder<ProfileCubit, AppSettings>(
        builder: (context, settings) {
          final cubit = context.read<ProfileCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              InvestancoFormSection(
                label: t.settings.appearance,
                children: [
                  _Label(t.settings.theme),
                  const SizedBox(height: 8),
                  InvestancoPillToggle<AppThemeMode>(
                    selected: settings.themeMode,
                    onChanged: (mode) => unawaited(cubit.setThemeMode(mode)),
                    options: [
                      InvestancoPillToggleOption(
                        value: AppThemeMode.system,
                        label: t.settings.themeSystem,
                        icon: FontAwesomeIcons.circleHalfStroke,
                      ),
                      InvestancoPillToggleOption(
                        value: AppThemeMode.light,
                        label: t.settings.themeLight,
                        icon: FontAwesomeIcons.sun,
                      ),
                      InvestancoPillToggleOption(
                        value: AppThemeMode.dark,
                        label: t.settings.themeDark,
                        icon: FontAwesomeIcons.moon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Label(t.settings.language),
                  const SizedBox(height: 8),
                  InvestancoPillToggle<AppLocale>(
                    selected: LocaleSettings.currentLocale,
                    onChanged: (locale) =>
                        unawaited(LocaleSettings.setLocale(locale)),
                    options: [
                      InvestancoPillToggleOption(
                        value: AppLocale.pt,
                        label: t.settings.languagePt,
                      ),
                      InvestancoPillToggleOption(
                        value: AppLocale.en,
                        label: t.settings.languageEn,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InvestancoFormSection(
                label: t.settings.quotes,
                children: [
                  InvestancoTextField(
                    label: t.settings.brapiToken,
                    helperText: t.settings.brapiTokenHelp,
                    onSubmitted: (value) => unawaited(cubit.setBrapiToken(value)),
                    // Re-keyed per persisted value so the field reflects loads.
                    key: ValueKey('brapi-${settings.brapiToken}'),
                  ),
                  InvestancoTextField(
                    label: t.settings.finnhubToken,
                    helperText: t.settings.finnhubTokenHelp,
                    onSubmitted: (value) =>
                        unawaited(cubit.setFinnhubToken(value)),
                    key: ValueKey('finnhub-${settings.finnhubToken}'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InvestancoFormSection(
                label: t.settings.general,
                children: [
                  Row(
                    children: [
                      Expanded(child: _Label(t.settings.baseCurrency)),
                      Text(
                        settings.baseCurrency.code,
                        style: context.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
