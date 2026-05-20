import 'package:flutter_test/flutter_test.dart';
import 'package:investanco/core/error/failures.dart';
import 'package:investanco/features/auth/data/repositories/local_auth_repository.dart';

void main() {
  const repository = LocalAuthRepository();

  test('starts signed out', () {
    expect(repository.currentUser, isNull);
    expect(repository.watchAuthState(), emits(null));
  });

  test('refuses sign-in until Firebase is configured', () async {
    final result = await repository.signInWithGoogle();

    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure, isA<ServerFailure>()), (_) {});
  });

  test('sign-out is a no-op', () {
    expect(repository.signOut(), completes);
  });
}
