import 'package:flutter/material.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/core/app_info/app_version.dart';
import 'package:investanco/core/extensions/context_extensions.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Low-emphasis label at the bottom of the profile screen showing the running
/// app version. Lets the user confirm at a glance they're on the latest build.
/// Mirrors financo's `AppVersionFooter`.
class AppVersionFooter extends StatelessWidget {
  /// Creates the footer.
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final version = sl<AppVersion>().display;
    if (version.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        '${t.profile.version} $version',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.appColors.onBackgroundLight,
        ),
      ),
    );
  }
}
