import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/database/app_database.dart';
import 'package:investanco/core/money/currency.dart';
import 'package:investanco/features/profile/data/repositories/settings_repository_impl.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = SettingsRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('returns defaults on first run', () async {
    final settings = await repository.get();

    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.baseCurrency, Currency.brl);
    expect(settings.brapiToken, isNull);
  });

  test('persists changes and reads them back', () async {
    await repository.save(
      const AppSettings(themeMode: AppThemeMode.dark, brapiToken: 'tok'),
    );

    final settings = await repository.get();
    expect(settings.themeMode, AppThemeMode.dark);
    expect(settings.brapiToken, 'tok');
  });

  test('save overwrites the single settings row', () async {
    await repository.save(const AppSettings(themeMode: AppThemeMode.light));
    await repository.save(const AppSettings(themeMode: AppThemeMode.dark));

    expect((await repository.get()).themeMode, AppThemeMode.dark);
  });
}
