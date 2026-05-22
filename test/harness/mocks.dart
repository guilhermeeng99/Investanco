import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/core/money/money.dart';
import 'package:investanco/core/sync/remote_mirror.dart';
import 'package:investanco/core/utils/id_generator.dart';
import 'package:investanco/features/allocation/domain/repositories/asset_class_repository.dart';
import 'package:investanco/features/assets/domain/entities/asset.dart';
import 'package:investanco/features/assets/domain/repositories/asset_repository.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/institutions/domain/repositories/institution_repository.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/domain/repositories/settings_repository.dart';
import 'package:investanco/features/quotes/domain/datasources/index_data_source.dart';
import 'package:investanco/features/quotes/domain/datasources/quote_data_source.dart';
import 'package:investanco/features/quotes/domain/entities/index_point.dart';
import 'package:investanco/features/quotes/domain/entities/quote.dart';
import 'package:investanco/features/quotes/domain/market_cache_store.dart';
import 'package:investanco/features/quotes/domain/repositories/quote_repository.dart';
import 'package:investanco/features/snapshots/domain/repositories/snapshot_repository.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';
import 'package:investanco/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'factories/asset_class_factory.dart';
import 'factories/asset_factory.dart';
import 'factories/institution_factory.dart';
import 'factories/transaction_factory.dart';

// Centralized test doubles (mocktail). One per project boundary so no test
// re-declares its own. See CLAUDE.md → Harness Engineering.

// ── Repositories ────────────────────────────────────────────────────────────
class MockAssetRepository extends Mock implements AssetRepository {}

class MockInstitutionRepository extends Mock implements InstitutionRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockSnapshotRepository extends Mock implements SnapshotRepository {}

class MockAssetClassRepository extends Mock implements AssetClassRepository {}

class MockQuoteRepository extends Mock implements QuoteRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

// ── Data sources ────────────────────────────────────────────────────────────
class MockDio extends Mock implements Dio {}

class MockFxDataSource extends Mock implements FxDataSource {}

class MockIndexDataSource extends Mock implements IndexDataSource {}

class MockQuoteDataSource extends Mock implements QuoteDataSource {}

class MockMarketCacheStore extends Mock implements MarketCacheStore {}

// ── Services / blocs / cubits ───────────────────────────────────────────────
class MockSyncService extends Mock implements SyncService {}

class MockRemoteMirror extends Mock implements RemoteMirror {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockThemeCubit extends MockCubit<ThemeMode> implements ThemeCubit {}

// ── Firebase ────────────────────────────────────────────────────────────────
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

/// Fallback for `signInWithProvider(any())` / `signInWithPopup(any())`.
class FakeAuthProvider extends Fake implements AuthProvider {}

// ── Google Sign-In ──────────────────────────────────────────────────────────
class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

/// Fallback for `signInWithCredential(any())`.
class FakeAuthCredential extends Fake implements AuthCredential {}

// ── Fakes ───────────────────────────────────────────────────────────────────

/// Deterministic [IdGenerator] returning a fixed id (default `generated-id`).
class FakeIdGenerator implements IdGenerator {
  /// Creates a generator that always returns [id].
  const FakeIdGenerator([this.id = 'generated-id']);

  /// The id returned by every [newId] call.
  final String id;

  @override
  String newId() => id;
}

/// Configurable [QuoteDataSource] fake: returns [quotes], or a [NetworkFailure]
/// when [fail]. Supports every asset.
class FakeQuoteDataSource implements QuoteDataSource {
  /// Creates a fake serving [quotes] (or failing when [fail]).
  FakeQuoteDataSource(this.quotes, {this.fail = false});

  /// Quotes returned by [fetch] on success.
  final List<Quote> quotes;

  /// When true, [fetch] returns a [NetworkFailure].
  final bool fail;

  @override
  bool supports(Asset asset) => true;

  @override
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets) async =>
      fail ? const Left(NetworkFailure()) : Right(quotes);
}

/// Registers mocktail fallback values for every type passed via `any()` in the
/// suite. Called once globally from `test/flutter_test_config.dart`, so no test
/// repeats `registerFallbackValue`.
void registerCommonFallbacks() {
  registerFallbackValue(assetFactory());
  registerFallbackValue(assetClassFactory());
  registerFallbackValue(institutionFactory());
  registerFallbackValue(transactionFactory());
  registerFallbackValue(const AppSettings());
  registerFallbackValue(<String>[]);
  registerFallbackValue(<Asset>[]);
  registerFallbackValue(<String, dynamic>{});
  registerFallbackValue(const Money.zero(Currency.brl));
  registerFallbackValue(DateTime(2026));
  registerFallbackValue(EconomicIndex.cdi);
}
