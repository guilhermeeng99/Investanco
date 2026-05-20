import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/i18n/app_locale_cubit.dart';
import 'package:investanco/app/widgets/investanco_pill_toggle.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Language picker row: System / Portuguese / English, wired to [AppLocaleCubit]
/// (`null` = follow system). Mirrors the theme row visually.
class ProfileLanguageRow extends StatelessWidget {
  /// Creates the row.
  const ProfileLanguageRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<AppLocaleCubit, AppLocale?>(
      builder: (context, selected) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const _IconDisc(icon: FontAwesomeIcons.language),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.profile.language,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InvestancoPillToggle<AppLocale?>(
                selected: selected,
                onChanged: (locale) =>
                    unawaited(context.read<AppLocaleCubit>().setLocale(locale)),
                options: [
                  InvestancoPillToggleOption(
                    value: AppLocale.pt,
                    label: t.profile.languagePt,
                    icon: FontAwesomeIcons.flag,
                  ),
                  InvestancoPillToggleOption(
                    value: AppLocale.en,
                    label: t.profile.languageEn,
                    icon: FontAwesomeIcons.flagUsa,
                  ),
                  InvestancoPillToggleOption(
                    value: null,
                    label: t.profile.languageSystem,
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
