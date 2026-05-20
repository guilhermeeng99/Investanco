import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:investanco/app/di/injection_container.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/app_theme.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:investanco/gen/i18n/strings.g.dart';

/// Root widget: wires theme, routing and localization.
class InvestancoApp extends StatelessWidget {
  /// Creates the root app widget.
  const InvestancoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<SyncCubit>.value(value: sl<SyncCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Investanco',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: sl<AppRouter>().config,
            locale: TranslationProvider.of(context).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
          );
        },
      ),
    );
  }
}
