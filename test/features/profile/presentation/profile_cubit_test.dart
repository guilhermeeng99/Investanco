import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/profile/domain/entities/app_settings.dart';
import 'package:investanco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/app_settings_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockSettingsRepository repository;
  late MockThemeCubit themeCubit;

  setUp(() {
    repository = MockSettingsRepository();
    themeCubit = MockThemeCubit();
    when(() => themeCubit.setMode(ThemeMode.dark)).thenReturn(null);
  });

  ProfileCubit build() => ProfileCubit(repository, themeCubit);

  blocTest<ProfileCubit, AppSettings>(
    'load() emits the persisted settings',
    build: build,
    setUp: () => when(repository.get).thenAnswer(
      (_) async => appSettingsFactory(themeMode: AppThemeMode.dark),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [appSettingsFactory(themeMode: AppThemeMode.dark)],
  );

  blocTest<ProfileCubit, AppSettings>(
    'setThemeMode persists, applies the theme live and emits the update',
    build: build,
    setUp: () => when(() => repository.save(any())).thenAnswer((_) async {}),
    act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
    expect: () => [appSettingsFactory(themeMode: AppThemeMode.dark)],
    verify: (_) {
      verify(
        () => repository.save(appSettingsFactory(themeMode: AppThemeMode.dark)),
      ).called(1);
      verify(() => themeCubit.setMode(ThemeMode.dark)).called(1);
    },
  );
}
