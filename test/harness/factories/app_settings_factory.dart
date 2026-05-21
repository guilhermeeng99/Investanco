import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';

/// Test factory for [AppSettings]. Defaults to system theme + BRL base.
/// Never hardcode entities in tests.
AppSettings appSettingsFactory({
  AppThemeMode themeMode = AppThemeMode.system,
  Currency baseCurrency = Currency.brl,
}) {
  return AppSettings(themeMode: themeMode, baseCurrency: baseCurrency);
}
