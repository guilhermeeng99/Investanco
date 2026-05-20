import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/core/network/quote_api_keys.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/domain/repositories/settings_repository.dart';
import 'package:investanco/features/profile/presentation/theme_mode_mapper.dart';

/// Loads and mutates [AppSettings]. Applies theme changes live via [ThemeCubit]
/// and keeps [QuoteApiKeys] in sync so adapters pick up token changes at once.
class ProfileCubit extends Cubit<AppSettings> {
  /// Creates the cubit with defaults until [load] runs.
  ProfileCubit(this._repository, this._themeCubit, this._apiKeys)
      : super(const AppSettings());

  final SettingsRepository _repository;
  final ThemeCubit _themeCubit;
  final QuoteApiKeys _apiKeys;

  /// Loads persisted settings and publishes tokens to [QuoteApiKeys].
  Future<void> load() async {
    final settings = await _repository.get();
    _apiKeys.finnhubToken = settings.finnhubToken;
    emit(settings);
  }

  /// Changes and persists the theme mode, applying it immediately.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    await _repository.save(updated);
    _themeCubit.setMode(toFlutterThemeMode(mode));
    emit(updated);
  }

  /// Sets (or clears) the brapi token.
  Future<void> setBrapiToken(String? token) async {
    final trimmed = token?.trim();
    final updated = (trimmed == null || trimmed.isEmpty)
        ? state.copyWith(clearBrapiToken: true)
        : state.copyWith(brapiToken: trimmed);
    await _repository.save(updated);
    emit(updated);
  }

  /// Sets (or clears) the Finnhub token and publishes it to [QuoteApiKeys].
  Future<void> setFinnhubToken(String? token) async {
    final trimmed = token?.trim();
    final updated = (trimmed == null || trimmed.isEmpty)
        ? state.copyWith(clearFinnhubToken: true)
        : state.copyWith(finnhubToken: trimmed);
    await _repository.save(updated);
    _apiKeys.finnhubToken = updated.finnhubToken;
    emit(updated);
  }
}
