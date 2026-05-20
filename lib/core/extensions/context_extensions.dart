import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_colors.dart';

/// Ergonomic accessors for theme data, so widgets read
/// `context.appColors.positive` instead of resolving brightness by hand.
/// Mirrors financo's `context_extensions`.
extension ContextThemeX on BuildContext {
  /// The palette matching the current brightness.
  AppColorsData get appColors => AppColors.of(this);

  /// Shorthand for `Theme.of(context).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shorthand for `Theme.of(context).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Whether the active theme is dark — used by gradient/elevation tweaks.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
