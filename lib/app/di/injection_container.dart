import 'package:get_it/get_it.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Initializes all dependencies. Called once from `main()` before `runApp`.
///
/// Registrations are grouped by layer; feature modules add their own block as
/// they are implemented (see ROADMAP.md).
Future<void> init() async {
  _initCore();
  _initAppShell();
  _initInstitutions();
}

void _initCore() {
  sl
    ..registerLazySingleton<AppDatabase>(AppDatabase.new)
    ..registerLazySingleton<IdGenerator>(UuidGenerator.new);
}

void _initAppShell() {
  sl
    ..registerLazySingleton<AppRouter>(AppRouter.new)
    ..registerLazySingleton<ThemeCubit>(ThemeCubit.new);
}

void _initInstitutions() {
  sl
    ..registerLazySingleton<InstitutionRepository>(
      () => InstitutionRepositoryImpl(sl()),
    )
    ..registerFactory<InstitutionsCubit>(() => InstitutionsCubit(sl(), sl()));
}
