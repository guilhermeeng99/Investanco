import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/widgets/investanco_app_bar.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/core/utils/web_file_download.dart'
    if (dart.library.js_interop) 'package:investanco/core/utils/web_file_download_web.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/features/profile/presentation/widgets/app_version_footer.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_language_row.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_palette_picker.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_row.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_section.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_theme_row.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// User profile: identity header + preferences (theme, palette, language, base
/// currency) + get-the-app (web) + account (sign out) + danger zone (clear data).
/// Mirrors financo's profile screen. See `docs/specs/profile.md`.
class ProfilePage extends StatelessWidget {
  /// Creates the page.
  const ProfilePage({super.key});

  /// Route path.
  static const String routePath = '/profile';

  /// Route name.
  static const String routeName = 'profile';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create: (_) {
        final cubit = sl<ProfileCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.profile.signOut),
        content: Text(t.profile.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.profile.signOut),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.profile.clearData),
        content: Text(t.profile.clearDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: ctx.appColors.error,
            ),
            child: Text(t.profile.clearData),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<SyncService>().clear(auth.user.userId);
    result.fold(
      (failure) =>
          messenger.showSnackBar(SnackBar(content: Text(failure.message))),
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(t.profile.clearDataSuccess)),
      ),
    );
  }

  void _downloadApk() =>
      triggerBrowserUrlDownload('investanco.apk', 'investanco.apk');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InvestancoAppBar(title: t.profile.title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const _Header(),
          const SizedBox(height: 24),
          ProfileSection(
            label: t.profile.sectionPreferences,
            children: const [
              ProfileThemeRow(),
              ProfilePalettePicker(),
              ProfileLanguageRow(),
              _BaseCurrencyRow(),
            ],
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 20),
            ProfileSection(
              label: t.profile.sectionGetTheApp,
              children: [
                ProfileRow(
                  icon: FontAwesomeIcons.android,
                  title: t.profile.downloadApk,
                  subtitle: t.profile.downloadApkDescription,
                  accent: context.appColors.success,
                  trailing: FaIcon(
                    FontAwesomeIcons.download,
                    size: 14,
                    color: context.appColors.onBackgroundLight,
                  ),
                  onTap: _downloadApk,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ProfileSection(
            label: t.profile.sectionAccount,
            children: [
              ProfileRow(
                icon: FontAwesomeIcons.rightFromBracket,
                title: t.profile.signOut,
                accent: context.appColors.onBackgroundLight,
                onTap: () => unawaited(_confirmSignOut(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ProfileSection(
            label: t.profile.sectionDangerZone,
            children: [
              ProfileRow(
                icon: FontAwesomeIcons.triangleExclamation,
                title: t.profile.clearData,
                subtitle: t.profile.clearDataDescription,
                destructive: true,
                onTap: () => unawaited(_confirmClearData(context)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const AppVersionFooter(),
        ],
      ),
    );
  }
}

/// Identity card driven by the app-wide [AuthBloc].
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => switch (state) {
        AuthAuthenticated(:final user) => ProfileHeaderCard(
            name: user.name,
            email: user.email,
            photoUrl: user.photoUrl,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

/// Read-only base-currency row (the value the portfolio consolidates to).
class _BaseCurrencyRow extends StatelessWidget {
  const _BaseCurrencyRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, AppSettings>(
      builder: (context, settings) => ProfileRow(
        icon: FontAwesomeIcons.coins,
        title: t.profile.baseCurrency,
        trailing: Text(
          settings.baseCurrency.code,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.appColors.onBackgroundLight,
          ),
        ),
      ),
    );
  }
}
