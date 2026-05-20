import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/domain/repositories/auth_repository.dart';
import 'package:investanco/features/sync/domain/sync_service.dart';
import 'package:investanco/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/auth_user_factory.dart';

class _MockSyncService extends Mock implements SyncService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockSyncService syncService;
  late _MockAuthRepository authRepository;
  final user = authUserFactory();

  setUp(() {
    syncService = _MockSyncService();
    authRepository = _MockAuthRepository();
  });

  blocTest<SyncCubit, SyncState>(
    'syncs once when a user signs in',
    build: () {
      when(authRepository.watchAuthState)
          .thenAnswer((_) => Stream.value(user));
      when(() => syncService.sync(user.userId))
          .thenAnswer((_) async => const Right(unit));
      return SyncCubit(syncService, authRepository);
    },
    expect: () => [const SyncInProgress(), isA<SyncSuccess>()],
    verify: (_) => verify(() => syncService.sync(user.userId)).called(1),
  );

  blocTest<SyncCubit, SyncState>(
    'emits failure when the sync fails',
    build: () {
      when(authRepository.watchAuthState)
          .thenAnswer((_) => Stream.value(user));
      when(() => syncService.sync(any()))
          .thenAnswer((_) async => const Left(ServerFailure('down')));
      return SyncCubit(syncService, authRepository);
    },
    expect: () => [const SyncInProgress(), const SyncFailure('down')],
  );

  blocTest<SyncCubit, SyncState>(
    'stays idle while signed out',
    build: () {
      when(authRepository.watchAuthState)
          .thenAnswer((_) => Stream<AuthUser?>.value(null));
      return SyncCubit(syncService, authRepository);
    },
    expect: () => <SyncState>[],
    verify: (_) => verifyNever(() => syncService.sync(any())),
  );

  blocTest<SyncCubit, SyncState>(
    'syncNow runs for the current user',
    build: () {
      when(authRepository.watchAuthState)
          .thenAnswer((_) => Stream<AuthUser?>.value(null));
      when(() => authRepository.currentUser).thenReturn(user);
      when(() => syncService.sync(user.userId))
          .thenAnswer((_) async => const Right(unit));
      return SyncCubit(syncService, authRepository);
    },
    act: (cubit) => cubit.syncNow(),
    expect: () => [const SyncInProgress(), isA<SyncSuccess>()],
  );
}
