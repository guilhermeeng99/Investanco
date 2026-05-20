import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/app/theme/app_colors.dart';
import 'package:investanco/app/theme/dark_palettes.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _darkPaletteKey = 'dark_palette';

/// Tracks the active dark-mode palette, persisted per device. Updates
/// [AppColors.dark] so the next theme rebuild picks up the new colours.
/// Mirrors financo's `DarkPaletteCubit`.
class DarkPaletteCubit extends Cubit<DarkPalette> {
  /// Loads the persisted palette and applies it.
  DarkPaletteCubit(this._prefs) : super(DarkPalettes.defaultId) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final value = _prefs.getString(_darkPaletteKey);
    final palette = value == null
        ? state
        : DarkPalette.values.where((p) => p.name == value).firstOrNull ??
            state;
    _apply(palette);
    if (palette != state) emit(palette);
  }

  /// Persists and applies [palette].
  Future<void> setPalette(DarkPalette palette) async {
    await _prefs.setString(_darkPaletteKey, palette.name);
    _apply(palette);
    emit(palette);
  }

  void _apply(DarkPalette palette) {
    AppColors.dark = DarkPalettes.byId(palette).colors;
  }
}
