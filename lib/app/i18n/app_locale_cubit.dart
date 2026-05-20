import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:investanco/gen/i18n/strings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';
const _systemSentinel = 'system';

/// User-facing locale preference. `null` means "follow system" — slang's
/// [AppLocaleUtils.findDeviceLocale] picks the closest supported [AppLocale].
/// Any explicit choice is persisted and survives restarts. Mirrors financo.
class AppLocaleCubit extends Cubit<AppLocale?> {
  /// Loads the persisted preference and applies it.
  AppLocaleCubit(this._prefs) : super(null) {
    _load();
  }

  final SharedPreferences _prefs;

  void _load() {
    final resolved = _resolveStored(_prefs.getString(_localeKey));
    // Sync apply for the first frame; setLocale (async) is used afterwards so
    // TranslationProvider also rebuilds the running tree.
    LocaleSettings.setLocaleSync(resolved ?? AppLocaleUtils.findDeviceLocale());
    if (resolved != state) emit(resolved);
  }

  /// Sets (or clears, when [locale] is null) the locale preference.
  Future<void> setLocale(AppLocale? locale) async {
    await _prefs.setString(
      _localeKey,
      locale == null ? _systemSentinel : _tag(locale),
    );
    await LocaleSettings.setLocale(locale ?? AppLocaleUtils.findDeviceLocale());
    emit(locale);
  }

  AppLocale? _resolveStored(String? stored) {
    if (stored == null || stored == _systemSentinel) return null;
    return AppLocale.values.where((l) => _tag(l) == stored).firstOrNull;
  }

  static String _tag(AppLocale locale) => locale.countryCode == null
      ? locale.languageCode
      : '${locale.languageCode}-${locale.countryCode}';
}
