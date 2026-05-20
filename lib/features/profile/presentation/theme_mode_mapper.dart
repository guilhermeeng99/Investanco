import 'package:flutter/material.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';

/// Maps the domain [AppThemeMode] to Flutter's [ThemeMode].
ThemeMode toFlutterThemeMode(AppThemeMode mode) => switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
