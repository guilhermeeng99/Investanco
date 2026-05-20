import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the active [ThemeMode]. Session-independent singleton (see CLAUDE.md).
class ThemeCubit extends Cubit<ThemeMode> {
  /// Starts following the system theme.
  ThemeCubit() : super(ThemeMode.system);

  /// Sets an explicit [mode].
  void setMode(ThemeMode mode) => emit(mode);

  /// Toggles between light and dark.
  void toggle() =>
      emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
