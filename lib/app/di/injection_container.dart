import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:get_it/get_it.dart';
import 'package:investanco/app/i18n/app_locale_cubit.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/dark_palette_cubit.dart';
import 'package:investanco/app/theme/light_palette_cubit.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/core/app_info/app_version.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/network/dio_client.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
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
import 'package:investanco/features/quotes/data/datasources/bcb_sgs_index_data_source.dart';
import 'package:investanco/features/quotes/data/datasources/brapi_quote_data_source.dart';
import 'package:investanco/features/quotes/data/datasources/finnhub_quote_data_source.dart';
import 'package:investanco/features/quotes/data/datasources/tesouro_direto_data_source.dart';
import 'package:investanco/features/quotes/data/repositories/quote_repository_impl.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/data/repositories/snapshot_repository_impl.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:investanco/features/sync/data/firestore_remote_mirror.dart';
import 'package:investanco/features/sync/data/firestore_sync_service.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';
import 'package:investanco/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:investanco/features/transactions/presentation/cubit/transactions_cubit.dart';
import 'package:investanco/features/valuation/domain/valuation_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Initializes all dependencies. Called once from `main()` before `runApp`.
///
/// Registrations are grouped by layer; feature modules add their own block as
/// they are implemented (see docs/ROADMAP.md).
Future<void> init() async {
  await _initPrefs();
  await _initAppInfo();
  _initCore();
  _initAppShell();
  _initAuth();
  _initSync();
  _initInstitutions();
  _initAssets();
  _initTransactions();
  _initQuotes();
  _initDashboard();
  _initProfile();
  _initPreferences();
  await _loadTheme();
}

/// Device-local key/value store (locale + palette preferences).
Future<void> _initPrefs() async {
  sl.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
}

/// Reads the running app version once, for the profile footer. Best-effort: the
/// package_info plugin can be unregistered (e.g. right after adding it, before a
/// full restart), so a failure must not block boot over a version label.
Future<void> _initAppInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    sl.registerSingleton<AppVersion>(AppVersion(version: info.version));
  } on Object {
    sl.registerSingleton<AppVersion>(const AppVersion(version: ''));
  }
}

/// App-wide locale + palette cubits. Eagerly resolved so they load and apply
/// the active locale + palette colours before the first frame.
void _initPreferences() {
  sl
    ..registerLazySingleton<AppLocaleCubit>(() => AppLocaleCubit(sl()))
    ..registerLazySingleton<LightPaletteCubit>(() => LightPaletteCubit(sl()))
    ..registerLazySingleton<DarkPaletteCubit>(() => DarkPaletteCubit(sl()))
    ..get<AppLocaleCubit>()
    ..get<LightPaletteCubit>()
    ..get<DarkPaletteCubit>();
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
    ..registerLazySingleton<AppRouter>(() => AppRouter(sl()))
    ..registerLazySingleton<ThemeCubit>(ThemeCubit.new);
}

/// Auth: Firebase Auth + Google sign-in behind [AuthRepository]. The bloc is an
/// app-wide singleton (provided at the root, consumed by Settings).
void _initAuth() {
  sl
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(fb.FirebaseAuth.instance),
    )
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(sl()));
}

/// Cloud sync: mirrors Drift to the signed-in user's Firestore. The per-session
/// sync runs at sign-in, owned by [StartupCubit] (see `docs/specs/cloud_sync.md`).
void _initSync() {
  sl
    ..registerLazySingleton<SyncService>(
      () => FirestoreSyncService(sl(), FirebaseFirestore.instance),
    )
    ..registerLazySingleton<RemoteMirror>(
      () => FirestoreRemoteMirror(FirebaseFirestore.instance, sl()),
    )
    ..registerLazySingleton<StartupCubit>(() => StartupCubit(sl(), sl()));
}

void _initInstitutions() {
  sl
    ..registerLazySingleton<InstitutionRepository>(
      () => InstitutionRepositoryImpl(sl(), sl()),
    )
    ..registerFactory<InstitutionsCubit>(() => InstitutionsCubit(sl(), sl()));
}

void _initAssets() {
  sl
    ..registerLazySingleton<AssetRepository>(
      () => AssetRepositoryImpl(sl(), sl()),
    )
    ..registerFactory<AssetsCubit>(() => AssetsCubit(sl(), sl()));
}

void _initTransactions() {
  sl
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepositoryImpl(sl(), sl()),
    )
    ..registerFactory<TransactionsCubit>(
      () => TransactionsCubit(sl(), sl(), sl(), sl()),
    );
}

void _initQuotes() {
  sl
    ..registerLazySingleton<Dio>(createDio)
    ..registerLazySingleton<FxDataSource>(() => AwesomeApiFxDataSource(sl()))
    ..registerLazySingleton<IndexDataSource>(() => BcbSgsIndexDataSource(sl()))
    ..registerLazySingleton<QuoteRepository>(
      () => QuoteRepositoryImpl(sl(), [
        BrapiQuoteDataSource(sl()),
        FinnhubQuoteDataSource(sl()),
        TesouroDiretoDataSource(sl()),
      ]),
    );
}

void _initDashboard() {
  sl
    ..registerLazySingleton<SnapshotRepository>(
      () => SnapshotRepositoryImpl(sl(), sl()),
    )
    ..registerFactory<DashboardCubit>(
      () => DashboardCubit(sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl(), sl()),
    );
}

void _initProfile() {
  sl
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl()),
    )
    ..registerFactory<ProfileCubit>(() => ProfileCubit(sl(), sl()));
}

/// Applies the persisted theme before the first frame. Market-data tokens are
/// baked in at build time via dart-define (`BRAPI_TOKEN` / `FINNHUB_TOKEN`),
/// read directly by the quote adapters — not stored or entered in-app.
Future<void> _loadTheme() async {
  final settings = await sl<SettingsRepository>().get();
  sl<ThemeCubit>().setMode(toFlutterThemeMode(settings.themeMode));
}
