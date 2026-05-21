import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:investanco/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:investanco/features/auth/domain/entities/auth_user.dart';
import 'package:mocktail/mocktail.dart';

import '../../../harness/mocks.dart';

void main() {
  late MockFirebaseAuth auth;
  late MockGoogleSignIn googleSignIn;
  late FirebaseAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(FakeAuthProvider());
  });

  setUp(() {
    auth = MockFirebaseAuth();
    googleSignIn = MockGoogleSignIn();
    repository = FirebaseAuthRepository(auth, googleSignIn);
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

  // Stubs a successful native mobile sign-in returning [user]. Tests run on the
  // Dart VM (kIsWeb == false), so signInWithGoogle takes the mobile path:
  // google_sign_in.authenticate() → GoogleAuthProvider.credential → Firebase.
  void stubMobileSignIn(MockFirebaseUser user) {
    final account = MockGoogleSignInAccount();
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
    when(() => googleSignIn.authenticate()).thenAnswer((_) async => account);
    final credential = MockUserCredential();
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => credential);
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
    stubMobileSignIn(stubbedUser());

    final result = await repository.signInWithGoogle();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw Exception()).userId, 'u1');
  });

  test('signInWithGoogle uses native google_sign_in, not the web redirect',
      () async {
    // Regression: signInWithProvider opens a Custom Tab web redirect through
    // firebaseapp.com/__/auth/handler, which fails with "missing initial state"
    // on Android. Mobile must use the native google_sign_in flow instead.
    stubMobileSignIn(stubbedUser());

    await repository.signInWithGoogle();

    verify(() => googleSignIn.authenticate()).called(1);
    verify(() => auth.signInWithCredential(any())).called(1);
    verifyNever(() => auth.signInWithProvider(any()));
  });

  test('signInWithGoogle maps a cancelled chooser to a failure', () async {
    when(() => googleSignIn.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isLeft(), isTrue);
  });

  test('signInWithGoogle maps a FirebaseAuthException to a failure', () async {
    final account = MockGoogleSignInAccount();
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
    when(() => googleSignIn.authenticate()).thenAnswer((_) async => account);
    when(() => auth.signInWithCredential(any())).thenThrow(
      fb.FirebaseAuthException(code: 'invalid-credential', message: 'bad'),
    );

    final result = await repository.signInWithGoogle();

    expect(result.isLeft(), isTrue);
  });

  test('signOut clears both the Google and Firebase sessions', () async {
    when(() => googleSignIn.signOut()).thenAnswer((_) async {});
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => googleSignIn.signOut()).called(1);
    verify(() => auth.signOut()).called(1);
  });

  test('signOut still signs out of Firebase when Google sign-out throws',
      () async {
    // Non-fatal: a Google sign-out failure must not block Firebase sign-out.
    when(() => googleSignIn.signOut())
        .thenThrow(StateError('GoogleSignIn not initialized'));
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
