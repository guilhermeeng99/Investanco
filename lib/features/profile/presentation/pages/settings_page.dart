import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/widgets.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/features/sync/presentation/cubit/sync_cubit.dart';
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
              const _AccountSection(),
              const SizedBox(height: 24),
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

/// Cloud account: Google sign-in to enable multi-device sync. Renders the
/// signed-in user or a sign-in button off the app-wide [AuthBloc].
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return InvestancoFormSection(
      label: t.settings.account,
      children: [
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => switch (state) {
            AuthAuthenticated(:final user) => _signedIn(context, user),
            _ => _signedOut(context, state),
          },
        ),
      ],
    );
  }

  Widget _signedIn(BuildContext context, AuthUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          user.name.isEmpty ? user.email : user.name,
          style: context.textTheme.titleSmall,
        ),
        if (user.name.isNotEmpty && user.email.isNotEmpty)
          Text(user.email, style: context.textTheme.bodySmall),
        const SizedBox(height: 12),
        BlocBuilder<SyncCubit, SyncState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InvestancoButton(
                label: t.settings.syncNow,
                isLoading: state is SyncInProgress,
                onPressed: () => context.read<SyncCubit>().syncNow(),
              ),
              if (state is SyncFailure) ...[
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: context.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        InvestancoButton(
          label: t.settings.signOut,
          isOutlined: true,
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthSignOutRequested()),
        ),
      ],
    );
  }

  Widget _signedOut(BuildContext context, AuthState state) {
    final message = state is AuthUnauthenticated ? state.message : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.settings.accountHelp, style: context.textTheme.bodySmall),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        InvestancoButton(
          label: t.settings.signInGoogle,
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthSignInRequested()),
        ),
      ],
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
