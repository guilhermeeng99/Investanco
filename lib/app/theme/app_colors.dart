import 'package:flutter/material.dart';

/// Immutable colour palette consumed by `AppTheme` and the shared widgets.
///
/// Mirrors financo's `AppColorsData` so both apps share the same design
/// language, adapted to an investment context (gains/losses instead of
/// income/expense). Resolve the active palette for the current brightness
/// with [AppColors.of].
class AppColorsData {
  /// Creates a palette. Every role is explicit so themes stay predictable.
  const AppColorsData({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.onBackground,
    required this.onBackgroundLight,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.warning,
    required this.success,
    required this.error,
  });

  /// Brand colour, used for primary actions and selected states.
  final Color primary;

  /// Lighter brand tint (gradients, hover, dark-mode primary).
  final Color primaryLight;

  /// Darker brand shade (pressed states, gradients).
  final Color primaryDark;

  /// Accent for secondary emphasis (links, informational chips).
  final Color secondary;

  /// Scaffold background.
  final Color background;

  /// Card / sheet surface.
  final Color surface;

  /// Subtle surface for fills, inputs and dividers.
  final Color surfaceVariant;

  /// Primary text colour on [background] / [surface].
  final Color onBackground;

  /// Muted text colour for captions and secondary labels.
  final Color onBackgroundLight;

  /// Positive movement (gains, buys credited to the portfolio).
  final Color positive;

  /// Negative movement (losses).
  final Color negative;

  /// Neutral / zero movement.
  final Color neutral;

  /// Warning state.
  final Color warning;

  /// Success state.
  final Color success;

  /// Error state.
  final Color error;
}

/// Single source of truth for brand + semantic colours.
///
/// Usage:
/// ```dart
/// final colors = AppColors.of(context);
/// Text('+2,3%', style: TextStyle(color: colors.positive));
/// ```
abstract final class AppColors {
  /// Seed colour for the Material 3 scheme (growth green).
  static const Color seed = Color(0xFF00A868);

  /// Active light palette. Mutable so the palette picker can swap it; the next
  /// theme rebuild (driven by `LightPaletteCubit`) picks up the new colours.
  static AppColorsData light = const AppColorsData(
    primary: Color(0xFF00A868),
    primaryLight: Color(0xFF2ECC8F),
    primaryDark: Color(0xFF007A4D),
    secondary: Color(0xFF2F6FED),
    background: Color(0xFFF4F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEAF0EC),
    onBackground: Color(0xFF14181B),
    onBackgroundLight: Color(0xFF5F6B66),
    positive: Color(0xFF1B873F),
    negative: Color(0xFFD32F2F),
    neutral: Color(0xFF6B7280),
    warning: Color(0xFFF59E0B),
    success: Color(0xFF1B873F),
    error: Color(0xFFD32F2F),
  );

  /// Active dark palette. Mutable so the palette picker can swap it.
  static AppColorsData dark = const AppColorsData(
    primary: Color(0xFF2ECC8F),
    primaryLight: Color(0xFF5BE0AC),
    primaryDark: Color(0xFF00A868),
    secondary: Color(0xFF5B9BE6),
    background: Color(0xFF0E1311),
    surface: Color(0xFF161D1A),
    surfaceVariant: Color(0xFF1F2925),
    onBackground: Color(0xFFE6ECE8),
    onBackgroundLight: Color(0xFF93A29B),
    positive: Color(0xFF34D17F),
    negative: Color(0xFFEF5350),
    neutral: Color(0xFF8B96A0),
    warning: Color(0xFFFBBF24),
    success: Color(0xFF34D17F),
    error: Color(0xFFEF5350),
  );

  /// Returns the palette matching the current theme brightness.
  static AppColorsData of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
