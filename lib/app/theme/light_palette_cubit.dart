import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/app/theme/light_palettes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lightPaletteKey = 'light_palette';

/// Tracks the active light-mode palette, persisted per device. Updates
/// [AppColors.light] so the next theme rebuild picks up the new colours.
/// Mirrors financo's `LightPaletteCubit`.
class LightPaletteCubit extends Cubit<LightPalette> {
  /// Loads the persisted palette and applies it.
  LightPaletteCubit(this._prefs) : super(LightPalettes.defaultId) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final value = _prefs.getString(_lightPaletteKey);
    final palette = value == null
        ? state
        : LightPalette.values.where((p) => p.name == value).firstOrNull ??
            state;
    _apply(palette);
    if (palette != state) emit(palette);
  }

  /// Persists and applies [palette].
  Future<void> setPalette(LightPalette palette) async {
    await _prefs.setString(_lightPaletteKey, palette.name);
    _apply(palette);
    emit(palette);
  }

  void _apply(LightPalette palette) {
    AppColors.light = LightPalettes.byId(palette).colors;
  }
}
