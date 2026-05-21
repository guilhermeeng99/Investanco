import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:investanco/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/factories/auth_user_factory.dart';
import '../../../harness/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late MockSyncService syncService;
  final user = authUserFactory();

  setUp(() {
    repository = MockAuthRepository();
    syncService = MockSyncService();
  });

  blocTest<AuthBloc, AuthState>(
    'AuthStarted emits Authenticated when the stream has a user',
    build: () {
      when(repository.watchAuthState).thenAnswer((_) => Stream.value(user));
      return AuthBloc(repository, syncService);
    },
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [AuthAuthenticated(user)],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted emits Unauthenticated when the stream is empty',
    build: () {
      when(repository.watchAuthState)
          .thenAnswer((_) => Stream<AuthUser?>.value(null));
      return AuthBloc(repository, syncService);
    },
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthSignInRequested emits Authenticated on success',
    build: () {
      when(() => repository.signInWithGoogle())
          .thenAnswer((_) async => Right<Failure, AuthUser>(user));
      return AuthBloc(repository, syncService);
    },
    act: (bloc) => bloc.add(const AuthSignInRequested()),
    expect: () => [const AuthInProgress(), AuthAuthenticated(user)],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthSignInRequested emits Unauthenticated with the failure message',
    build: () {
      when(() => repository.signInWithGoogle()).thenAnswer(
        (_) async => const Left<Failure, AuthUser>(ServerFailure('nope')),
      );
      return AuthBloc(repository, syncService);
    },
    act: (bloc) => bloc.add(const AuthSignInRequested()),
    expect: () => [
      const AuthInProgress(),
      const AuthUnauthenticated(message: 'nope'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthSignOutRequested signs out and wipes local data (no cross-account leak)',
    build: () {
      when(() => repository.signOut()).thenAnswer((_) async {});
      when(() => syncService.resetLocal()).thenAnswer((_) async {});
      return AuthBloc(repository, syncService);
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    verify: (_) {
      verify(() => repository.signOut()).called(1);
      verify(() => syncService.resetLocal()).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'AuthSignOutRequested still completes when the local wipe fails',
    build: () {
      when(() => repository.signOut()).thenAnswer((_) async {});
      when(() => syncService.resetLocal())
          .thenThrow(Exception('drift down'));
      return AuthBloc(repository, syncService);
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    verify: (_) => verify(() => repository.signOut()).called(1),
  );
}
