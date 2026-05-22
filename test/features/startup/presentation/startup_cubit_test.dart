import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:investanco/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/auth_user_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockAuthBloc authBloc;
  late MockSyncService syncService;
  final user = authUserFactory();

  setUp(() {
    authBloc = MockAuthBloc();
    syncService = MockSyncService();
  });

  StartupCubit build() => StartupCubit(authBloc, syncService);

  blocTest<StartupCubit, StartupState>(
    'routes to unauthenticated when already signed out',
    setUp: () =>
        when(() => authBloc.state).thenReturn(const AuthUnauthenticated()),
    build: build,
    act: (cubit) => cubit.initialize(),
    expect: () => const [
      StartupLoading(step: StartupStep.checkingAuth, progress: 0),
      StartupUnauthenticated(),
    ],
    verify: (_) => verifyNever(() => syncService.sync(any())),
  );

  blocTest<StartupCubit, StartupState>(
    'syncs then authenticates when signed in',
    setUp: () {
      when(() => authBloc.state).thenReturn(AuthAuthenticated(user));
      when(() => syncService.sync(user.userId))
          .thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) => cubit.initialize(),
    expect: () => [
      const StartupLoading(step: StartupStep.checkingAuth, progress: 0),
      const StartupLoading(step: StartupStep.syncing, progress: 0.3),
      StartupAuthenticated(userId: user.userId),
    ],
    verify: (_) => verify(() => syncService.sync(user.userId)).called(1),
  );

  blocTest<StartupCubit, StartupState>(
    'surfaces an error when the sync fails',
    setUp: () {
      when(() => authBloc.state).thenReturn(AuthAuthenticated(user));
      when(() => syncService.sync(user.userId))
          .thenAnswer((_) async => const Left(ServerFailure('down')));
    },
    build: build,
    act: (cubit) => cubit.initialize(),
    expect: () => const [
      StartupLoading(step: StartupStep.checkingAuth, progress: 0),
      StartupLoading(step: StartupStep.syncing, progress: 0.3),
      StartupError(ServerFailure('down')),
    ],
  );

  test('waits for the auth stream to resolve when state is unknown', () async {
    final controller = StreamController<AuthState>.broadcast();
    addTearDown(controller.close);
    AuthState current = const AuthUnknown();
    when(() => authBloc.state).thenAnswer((_) => current);
    when(() => authBloc.stream).thenAnswer((_) => controller.stream);
    when(() => syncService.sync(user.userId))
        .thenAnswer((_) async => const Right(unit));

    final cubit = build();
    final states = <StartupState>[];
    final subscription = cubit.stream.listen(states.add);

    final future = cubit.initialize();
    await Future<void>.delayed(Duration.zero);
    // Auth resolves only now — the cubit must have been waiting on the stream.
    current = AuthAuthenticated(user);
    controller.add(AuthAuthenticated(user));
    await future;
    // Let the broadcast stream deliver the final emit to the listener.
    await Future<void>.delayed(Duration.zero);

    expect(states, [
      const StartupLoading(step: StartupStep.checkingAuth, progress: 0),
      const StartupLoading(step: StartupStep.syncing, progress: 0.3),
      StartupAuthenticated(userId: user.userId),
    ]);

    await subscription.cancel();
    await cubit.close();
  });
}
