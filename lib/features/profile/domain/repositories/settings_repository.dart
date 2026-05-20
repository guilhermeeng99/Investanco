import 'package:investanco/features/profile/domain/entities/app_settings.dart';

/// Persistence for the single [AppSettings] record. See `docs/specs/profile.md`.
abstract class SettingsRepository {
  /// Returns the stored settings, or defaults on first run.
  Future<AppSettings> get();

  /// Persists the settings.
  Future<void> save(AppSettings settings);
}
