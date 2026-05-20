import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/network/dio_client.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
import 'package:investanco/features/profile/data/repositories/settings_repository_impl.dart';
import 'package:investanco/features/profile/domain/repositories/settings_repository.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:investanco/features/profile/presentation/theme_mode_mapper.dart';
import 'package:investanco/features/quotes/data/datasources/awesomeapi_fx_data_source.dart';
import 'package:investanco/features/quotes/data/datasources/brapi_quote_data_source.dart';
import 'package:investanco/features/quotes/data/datasources/yahoo_quote_data_source.dart';
import 'package:investanco/features/quotes/data/repositories/quote_repository_impl.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/data/repositories/snapshot_repository_impl.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';

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
  _initAssets();
  _initTransactions();
  _initQuotes();
  _initDashboard();
  _initProfile();
  await _loadTheme();
}

void _initCore() {
  sl
    ..registerLazySingleton<AppDatabase>(AppDatabase.new)
    ..registerLazySingleton<IdGenerator>(UuidGenerator.new)
    ..registerLazySingleton<HoldingCalculator>(HoldingCalculator.new)
    ..registerLazySingleton<ValuationService>(ValuationService.new);
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

void _initAssets() {
  sl
    ..registerLazySingleton<AssetRepository>(() => AssetRepositoryImpl(sl()))
    ..registerFactory<AssetsCubit>(() => AssetsCubit(sl(), sl()));
}

void _initTransactions() {
  sl
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(sl()),
    )
    ..registerFactory<TransactionsCubit>(
      () => TransactionsCubit(sl(), sl(), sl(), sl()),
    );
}

void _initQuotes() {
  sl
    ..registerLazySingleton<Dio>(createDio)
    ..registerLazySingleton<FxDataSource>(() => AwesomeApiFxDataSource(sl()))
    ..registerLazySingleton<QuoteRepository>(
      () => QuoteRepositoryImpl(sl(), [
        BrapiQuoteDataSource(sl()),
        YahooQuoteDataSource(sl()),
      ]),
    );
}

void _initDashboard() {
  sl
    ..registerLazySingleton<SnapshotRepository>(
      () => SnapshotRepositoryImpl(sl()),
    )
    ..registerFactory<DashboardCubit>(
      () => DashboardCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    );
}

void _initProfile() {
  sl
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()),
    )
    ..registerFactory<ProfileCubit>(() => ProfileCubit(sl(), sl()));
}

/// Applies the persisted theme before the first frame.
Future<void> _loadTheme() async {
  final settings = await sl<SettingsRepository>().get();
  sl<ThemeCubit>().setMode(toFlutterThemeMode(settings.themeMode));
}
