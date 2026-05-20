import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/i18n/app_locale_cubit.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/app_theme.dart';
import 'package:investanco/app/theme/dark_palette_cubit.dart';
import 'package:investanco/app/theme/dark_palettes.dart';
import 'package:investanco/app/theme/light_palette_cubit.dart';
import 'package:investanco/app/theme/light_palettes.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Root widget: wires theme (mode + palette), routing and localization.
class InvestancoApp extends StatelessWidget {
  /// Creates the root app widget.
  const InvestancoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<StartupCubit>.value(value: sl<StartupCubit>()),
        BlocProvider<AppLocaleCubit>.value(value: sl<AppLocaleCubit>()),
        BlocProvider<LightPaletteCubit>.value(value: sl<LightPaletteCubit>()),
        BlocProvider<DarkPaletteCubit>.value(value: sl<DarkPaletteCubit>()),
      ],
      // Theme mode + both palette cubits drive a rebuild so MaterialApp picks up
      // the freshly-applied AppColors (the palette cubits mutate AppColors.*).
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LightPaletteCubit, LightPalette>(
            builder: (context, _) {
              return BlocBuilder<DarkPaletteCubit, DarkPalette>(
                builder: (context, _) {
                  return MaterialApp.router(
                    title: 'Investanco',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeMode,
                    routerConfig: sl<AppRouter>().config,
                    locale: TranslationProvider.of(context).flutterLocale,
                    supportedLocales: AppLocaleUtils.supportedLocales,
                    localizationsDelegates:
                        GlobalMaterialLocalizations.delegates,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
