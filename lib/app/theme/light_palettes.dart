import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_colors.dart';

/// Light-mode palette catalog. The user picks one in Profile → Preferences; the
/// choice is persisted by `LightPaletteCubit` and feeds [AppColors.light].
/// Mirrors financo's palette system, adapted to Investanco's colour roles
/// (positive/negative/neutral instead of income/expense).
enum LightPalette { growthGreen, oceanBlue, indigo, sunsetCoral, violet, slate }

/// One catalog entry: id, display [label] and the full [colors] it applies.
class LightPaletteOption {
  /// Creates an option.
  const LightPaletteOption({
    required this.id,
    required this.label,
    required this.colors,
  });

  /// Stable id (persisted by name).
  final LightPalette id;

  /// Display label (proper noun, not localized).
  final String label;

  /// The palette this option applies.
  final AppColorsData colors;
}

/// Shared light-mode semantic colours (gains/losses/etc) reused across palettes;
/// only the brand + neutral surfaces change per palette.
const _positive = Color(0xFF1B873F);
const _negative = Color(0xFFD32F2F);
const _neutral = Color(0xFF6B7280);
const _warning = Color(0xFFF59E0B);

/// Light palette catalog.
abstract final class LightPalettes {
  /// Every selectable light palette (first is the default).
  static const List<LightPaletteOption> all = [
    LightPaletteOption(
      id: LightPalette.growthGreen,
      label: 'Growth Green',
      colors: AppColorsData(
        primary: Color(0xFF00A868),
        primaryLight: Color(0xFF2ECC8F),
        primaryDark: Color(0xFF007A4D),
        secondary: Color(0xFF2F6FED),
        background: Color(0xFFF4F7F5),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFEAF0EC),
        onBackground: Color(0xFF14181B),
        onBackgroundLight: Color(0xFF5F6B66),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    LightPaletteOption(
      id: LightPalette.oceanBlue,
      label: 'Ocean Blue',
      colors: AppColorsData(
        primary: Color(0xFF0EA5E9),
        primaryLight: Color(0xFF38BDF8),
        primaryDark: Color(0xFF0369A1),
        secondary: Color(0xFF14B8A6),
        background: Color(0xFFF0F9FF),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFE0F2FE),
        onBackground: Color(0xFF0C1F2C),
        onBackgroundLight: Color(0xFF52708A),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    LightPaletteOption(
      id: LightPalette.indigo,
      label: 'Indigo',
      colors: AppColorsData(
        primary: Color(0xFF5B5FEF),
        primaryLight: Color(0xFF7C83FF),
        primaryDark: Color(0xFF3F43C9),
        secondary: Color(0xFF22C55E),
        background: Color(0xFFF6F7FB),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFEEF0F6),
        onBackground: Color(0xFF1A1B1F),
        onBackgroundLight: Color(0xFF6B7280),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    LightPaletteOption(
      id: LightPalette.sunsetCoral,
      label: 'Sunset Coral',
      colors: AppColorsData(
        primary: Color(0xFFF97066),
        primaryLight: Color(0xFFFDA29B),
        primaryDark: Color(0xFFD92D20),
        secondary: Color(0xFFFB923C),
        background: Color(0xFFFFF7F3),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFFCE9E0),
        onBackground: Color(0xFF2A1410),
        onBackgroundLight: Color(0xFF7B5A52),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    LightPaletteOption(
      id: LightPalette.violet,
      label: 'Violet',
      colors: AppColorsData(
        primary: Color(0xFF8B5CF6),
        primaryLight: Color(0xFFA78BFA),
        primaryDark: Color(0xFF6D28D9),
        secondary: Color(0xFFEC4899),
        background: Color(0xFFF8F5FF),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFEDE7FA),
        onBackground: Color(0xFF1F1530),
        onBackgroundLight: Color(0xFF6B5C82),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    LightPaletteOption(
      id: LightPalette.slate,
      label: 'Slate',
      colors: AppColorsData(
        primary: Color(0xFF334155),
        primaryLight: Color(0xFF64748B),
        primaryDark: Color(0xFF1E293B),
        secondary: Color(0xFF0EA5E9),
        background: Color(0xFFFAFAFA),
        surface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFFF1F5F9),
        onBackground: Color(0xFF0F172A),
        onBackgroundLight: Color(0xFF64748B),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
  ];

  /// The default light palette id.
  static const LightPalette defaultId = LightPalette.growthGreen;

  /// Returns the option for [id], or the default.
  static LightPaletteOption byId(LightPalette id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}
