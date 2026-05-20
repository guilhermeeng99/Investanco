import 'package:flutter/material.dart';
import 'package:investanco/app/theme/app_colors.dart';

/// Dark-mode palette catalog (paired 1:1 with the light palettes by name). The user
/// picks one in Profile → Preferences; the choice is persisted by
/// `DarkPaletteCubit` and feeds [AppColors.dark]. Mirrors financo.
enum DarkPalette { growthGreen, oceanBlue, indigo, sunsetCoral, violet, slate }

/// One catalog entry: id, display [label] and the full [colors] it applies.
class DarkPaletteOption {
  /// Creates an option.
  const DarkPaletteOption({
    required this.id,
    required this.label,
    required this.colors,
  });

  /// Stable id (persisted by name).
  final DarkPalette id;

  /// Display label (proper noun, not localized).
  final String label;

  /// The palette this option applies.
  final AppColorsData colors;
}

/// Shared dark-mode semantic colours, reused across palettes.
const _positive = Color(0xFF34D17F);
const _negative = Color(0xFFEF5350);
const _neutral = Color(0xFF8B96A0);
const _warning = Color(0xFFFBBF24);

/// Dark palette catalog.
abstract final class DarkPalettes {
  /// Every selectable dark palette (first is the default).
  static const List<DarkPaletteOption> all = [
    DarkPaletteOption(
      id: DarkPalette.growthGreen,
      label: 'Growth Green',
      colors: AppColorsData(
        primary: Color(0xFF2ECC8F),
        primaryLight: Color(0xFF5BE0AC),
        primaryDark: Color(0xFF00A868),
        secondary: Color(0xFF5B9BE6),
        background: Color(0xFF0E1311),
        surface: Color(0xFF161D1A),
        surfaceVariant: Color(0xFF1F2925),
        onBackground: Color(0xFFE6ECE8),
        onBackgroundLight: Color(0xFF93A29B),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    DarkPaletteOption(
      id: DarkPalette.oceanBlue,
      label: 'Ocean Blue',
      colors: AppColorsData(
        primary: Color(0xFF38BDF8),
        primaryLight: Color(0xFF7DD3FC),
        primaryDark: Color(0xFF0EA5E9),
        secondary: Color(0xFF2DD4BF),
        background: Color(0xFF0A0F14),
        surface: Color(0xFF111922),
        surfaceVariant: Color(0xFF1B2733),
        onBackground: Color(0xFFE2ECF5),
        onBackgroundLight: Color(0xFF8FA3B5),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    DarkPaletteOption(
      id: DarkPalette.indigo,
      label: 'Indigo',
      colors: AppColorsData(
        primary: Color(0xFF7C83FF),
        primaryLight: Color(0xFFA5A9FF),
        primaryDark: Color(0xFF5B5FEF),
        secondary: Color(0xFF4ADE80),
        background: Color(0xFF0E0F14),
        surface: Color(0xFF16171F),
        surfaceVariant: Color(0xFF20222C),
        onBackground: Color(0xFFE7E8EE),
        onBackgroundLight: Color(0xFF9A9DB0),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    DarkPaletteOption(
      id: DarkPalette.sunsetCoral,
      label: 'Sunset Coral',
      colors: AppColorsData(
        primary: Color(0xFFFDA29B),
        primaryLight: Color(0xFFFEC8C3),
        primaryDark: Color(0xFFF97066),
        secondary: Color(0xFFFDBA74),
        background: Color(0xFF160F0D),
        surface: Color(0xFF211613),
        surfaceVariant: Color(0xFF2E211C),
        onBackground: Color(0xFFF5E6E2),
        onBackgroundLight: Color(0xFFB59A92),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    DarkPaletteOption(
      id: DarkPalette.violet,
      label: 'Violet',
      colors: AppColorsData(
        primary: Color(0xFFA78BFA),
        primaryLight: Color(0xFFC4B5FD),
        primaryDark: Color(0xFF8B5CF6),
        secondary: Color(0xFFF472B6),
        background: Color(0xFF120F18),
        surface: Color(0xFF1A1622),
        surfaceVariant: Color(0xFF26212E),
        onBackground: Color(0xFFEAE6F2),
        onBackgroundLight: Color(0xFFA39AB5),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
    DarkPaletteOption(
      id: DarkPalette.slate,
      label: 'Slate',
      colors: AppColorsData(
        primary: Color(0xFF94A3B8),
        primaryLight: Color(0xFFCBD5E1),
        primaryDark: Color(0xFF64748B),
        secondary: Color(0xFF38BDF8),
        background: Color(0xFF0B0F14),
        surface: Color(0xFF131820),
        surfaceVariant: Color(0xFF1E2530),
        onBackground: Color(0xFFE7ECF2),
        onBackgroundLight: Color(0xFF94A3B8),
        positive: _positive,
        negative: _negative,
        neutral: _neutral,
        warning: _warning,
        success: _positive,
        error: _negative,
      ),
    ),
  ];

  /// The default dark palette id.
  static const DarkPalette defaultId = DarkPalette.growthGreen;

  /// Returns the option for [id], or the default.
  static DarkPaletteOption byId(DarkPalette id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}
