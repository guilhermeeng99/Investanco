import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/currency.dart';

/// Theme preference (mapped to Flutter's `ThemeMode` in the presentation layer).
enum AppThemeMode { system, light, dark }

/// User preferences. Market-data tokens are not stored here — they are baked in
/// at build time via dart-define (see the quote adapters). See
/// `docs/specs/profile.md`.
class AppSettings extends Equatable {
  /// Creates settings (defaults: system theme, BRL base).
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.baseCurrency = Currency.brl,
  });

  /// Active theme preference.
  final AppThemeMode themeMode;

  /// Base currency for consolidation.
  final Currency baseCurrency;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    Currency? baseCurrency,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      baseCurrency: baseCurrency ?? this.baseCurrency,
    );
  }

  @override
  List<Object?> get props => [themeMode, baseCurrency];
}
