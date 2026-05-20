import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/currency.dart';

/// Theme preference (mapped to Flutter's `ThemeMode` in the presentation layer).
enum AppThemeMode { system, light, dark }

/// User preferences. See `docs/specs/profile.md`.
class AppSettings extends Equatable {
  /// Creates settings (defaults: system theme, BRL base, no brapi token).
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.baseCurrency = Currency.brl,
    this.brapiToken,
  });

  /// Active theme preference.
  final AppThemeMode themeMode;

  /// Base currency for consolidation.
  final Currency baseCurrency;

  /// Optional brapi API token (more quota/tickers).
  final String? brapiToken;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    Currency? baseCurrency,
    String? brapiToken,
    bool clearToken = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      brapiToken: clearToken ? null : (brapiToken ?? this.brapiToken),
    );
  }

  @override
  List<Object?> get props => [themeMode, baseCurrency, brapiToken];
}
