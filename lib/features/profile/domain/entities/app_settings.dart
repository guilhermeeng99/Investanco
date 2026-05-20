import 'package:equatable/equatable.dart';
import 'package:investanco/core/money/currency.dart';

/// Theme preference (mapped to Flutter's `ThemeMode` in the presentation layer).
enum AppThemeMode { system, light, dark }

/// User preferences. See `docs/specs/profile.md`.
class AppSettings extends Equatable {
  /// Creates settings (defaults: system theme, BRL base, no tokens).
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.baseCurrency = Currency.brl,
    this.brapiToken,
    this.finnhubToken,
  });

  /// Active theme preference.
  final AppThemeMode themeMode;

  /// Base currency for consolidation.
  final Currency baseCurrency;

  /// Optional brapi API token (more quota/tickers for BR assets).
  final String? brapiToken;

  /// Optional Finnhub API token (required to price US assets on web).
  final String? finnhubToken;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    Currency? baseCurrency,
    String? brapiToken,
    String? finnhubToken,
    bool clearBrapiToken = false,
    bool clearFinnhubToken = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      brapiToken: clearBrapiToken ? null : (brapiToken ?? this.brapiToken),
      finnhubToken:
          clearFinnhubToken ? null : (finnhubToken ?? this.finnhubToken),
    );
  }

  @override
  List<Object?> get props =>
      [themeMode, baseCurrency, brapiToken, finnhubToken];
}
