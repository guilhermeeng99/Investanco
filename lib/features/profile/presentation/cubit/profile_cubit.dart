import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/theme/theme_cubit.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/domain/repositories/settings_repository.dart';
import 'package:investanco/features/profile/presentation/theme_mode_mapper.dart';

/// Loads and mutates [AppSettings]. Applies theme changes live via [ThemeCubit].
/// Market-data tokens are build-time (dart-define), so they are not managed here.
class ProfileCubit extends Cubit<AppSettings> {
  /// Creates the cubit with defaults until [load] runs.
  ProfileCubit(this._repository, this._themeCubit)
      : super(const AppSettings());

  final SettingsRepository _repository;
  final ThemeCubit _themeCubit;

  /// Loads persisted settings.
  Future<void> load() async {
    emit(await _repository.get());
  }

  /// Changes and persists the theme mode, applying it immediately.
  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    await _repository.save(updated);
    _themeCubit.setMode(toFlutterThemeMode(mode));
    emit(updated);
  }
}
