import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/domain/repositories/settings_repository.dart';
import 'package:investanco/features/profile/presentation/theme_mode_mapper.dart';

/// Loads and mutates [AppSettings]. Applies theme changes live via [ThemeCubit].
class ProfileCubit extends Cubit<AppSettings> {
  /// Creates the cubit with defaults until [load] runs.
  ProfileCubit(this._repository, this._themeCubit)
      : super(const AppSettings());

  final SettingsRepository _repository;
  final ThemeCubit _themeCubit;

  /// Loads persisted settings.
  Future<void> load() async => emit(await _repository.get());

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
        ? state.copyWith(clearToken: true)
        : state.copyWith(brapiToken: trimmed);
    await _repository.save(updated);
    emit(updated);
  }
}
