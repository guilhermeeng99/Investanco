import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:investanco/app/i18n/app_locale_cubit.dart';
import 'package:investanco/app/widgets/investanco_pill_toggle.dart';
import 'package:investanco/features/profile/presentation/widgets/profile_segmented_row.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Language picker row: System / Portuguese / English, wired to [AppLocaleCubit]
/// (`null` = follow system). Mirrors the theme row visually.
class ProfileLanguageRow extends StatelessWidget {
  /// Creates the row.
  const ProfileLanguageRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLocaleCubit, AppLocale?>(
      builder: (context, selected) {
        return ProfileSegmentedRow<AppLocale?>(
          icon: FontAwesomeIcons.language,
          title: t.profile.language,
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
        );
      },
    );
  }
}
