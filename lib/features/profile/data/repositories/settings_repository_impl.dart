import 'package:drift/drift.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/domain/repositories/settings_repository.dart';

/// Drift-backed [SettingsRepository]. Stores a single row (id 0).
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates the repository over [_db].
  const SettingsRepositoryImpl(this._db);

  final AppDatabase _db;

  static const int _rowId = 0;

  @override
  Future<AppSettings> get() async {
    final row = await (_db.select(_db.settings)
          ..where((t) => t.id.equals(_rowId)))
        .getSingleOrNull();
    if (row == null) return const AppSettings();
    return AppSettings(
      themeMode: AppThemeMode.values.byName(row.themeMode),
      baseCurrency: Currency.values.byName(row.baseCurrency),
      brapiToken: row.brapiToken,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion(
            id: const Value(_rowId),
            themeMode: Value(settings.themeMode.name),
            baseCurrency: Value(settings.baseCurrency.name),
            brapiToken: Value(settings.brapiToken),
          ),
        );
  }
}
