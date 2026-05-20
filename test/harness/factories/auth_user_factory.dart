import 'package:investanco/features/auth/domain/entities/auth_user.dart';

/// Test factory for [AuthUser]. Never hardcode entities in tests.
AuthUser authUserFactory({
  String userId = 'u1',
  String name = 'Ada Lovelace',
  String email = 'ada@example.com',
  String? photoUrl,
}) {
  return AuthUser(
    userId: userId,
    name: name,
    email: email,
    photoUrl: photoUrl,
  );
}
