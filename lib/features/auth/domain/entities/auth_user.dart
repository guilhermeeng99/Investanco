import 'package:equatable/equatable.dart';

/// An authenticated user. `userId` becomes the owner id for cloud-synced data
/// (today everything is written against a local profile). See `docs/specs/auth.md`.
class AuthUser extends Equatable {
  /// Creates a user.
  const AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  /// Stable provider id (Firebase uid).
  final String userId;

  /// Display name.
  final String name;

  /// Account email.
  final String email;

  /// Avatar URL, when available.
  final String? photoUrl;

  @override
  List<Object?> get props => [userId, name, email, photoUrl];
}
