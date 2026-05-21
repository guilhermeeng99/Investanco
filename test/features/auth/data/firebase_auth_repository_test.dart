import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/mocks.dart';

void main() {
  late MockFirebaseAuth auth;
  late FirebaseAuthRepository repository;

  setUpAll(() => registerFallbackValue(FakeAuthProvider()));

  setUp(() {
    auth = MockFirebaseAuth();
    repository = FirebaseAuthRepository(auth);
  });

  // Builds a fully-stubbed Firebase user. Must be called outside any `when(...)`
  // (it stubs internally; mocktail forbids nested stubbing).
  MockFirebaseUser stubbedUser() {
    final user = MockFirebaseUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.displayName).thenReturn('Ada');
    when(() => user.email).thenReturn('ada@example.com');
    when(() => user.photoURL).thenReturn(null);
    return user;
  }

  test('currentUser maps the Firebase user to AuthUser', () {
    final user = stubbedUser();
    when(() => auth.currentUser).thenReturn(user);

    final result = repository.currentUser;

    expect(result?.userId, 'u1');
    expect(result?.name, 'Ada');
    expect(result?.email, 'ada@example.com');
    expect(result?.photoUrl, isNull);
  });

  test('currentUser is null when signed out', () {
    when(() => auth.currentUser).thenReturn(null);

    expect(repository.currentUser, isNull);
  });

  test('watchAuthState maps the auth-state stream', () async {
    final user = stubbedUser();
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));

    await expectLater(
      repository.watchAuthState(),
      emits(isA<AuthUser>().having((u) => u.userId, 'userId', 'u1')),
    );
  });

  test('signInWithGoogle returns the mapped user on success', () async {
    final user = stubbedUser();
    final credential = MockUserCredential();
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInWithProvider(any()))
        .thenAnswer((_) async => credential);

    final result = await repository.signInWithGoogle();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw Exception()).userId, 'u1');
  });

  test('signInWithGoogle maps a FirebaseAuthException to a failure', () async {
    when(() => auth.signInWithProvider(any())).thenThrow(
      fb.FirebaseAuthException(code: 'popup-closed', message: 'closed'),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isLeft(), isTrue);
  });

  test('signOut delegates to Firebase', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
