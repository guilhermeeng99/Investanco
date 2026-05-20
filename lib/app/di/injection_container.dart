import 'package:get_it/get_it.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/theme_cubit.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Initializes all dependencies. Called once from `main()` before `runApp`.
///
/// Registrations are grouped by layer; feature modules add their own block as
/// they are implemented (see ROADMAP.md).
Future<void> init() async {
  _initAppShell();
}

void _initAppShell() {
  sl
    ..registerLazySingleton<AppRouter>(AppRouter.new)
    ..registerLazySingleton<ThemeCubit>(ThemeCubit.new);
}
