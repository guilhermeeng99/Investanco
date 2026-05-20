import 'package:get_it/get_it.dart';
import 'package:investanco/app/router/app_router.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/assets/data/repositories/asset_repository_impl.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/assets/presentation/cubit/assets_cubit.dart';
import 'package:investanco/features/holdings/domain/holding_calculator.dart';
import 'package:investanco/features/institutions/data/repositories/institution_repository_impl.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/institutions/presentation/cubit/institutions_cubit.dart';
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
