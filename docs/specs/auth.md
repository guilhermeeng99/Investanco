# Spec: Auth *(foundation built — Firebase impl deferred, Phase 6)*

Authentication is **not** required for v1 (offline-first, single local profile).
The Firebase-agnostic **foundation** (entity, repository port, `AuthBloc`) is now
implemented and unit-tested so cloud sync can be added without rework. Only the
concrete `FirebaseAuthRepository` + `firebase_options.dart` remain (need the
user's Firebase project).

## Goal

Firebase Auth + Google Sign-In, so the local Drift data can be mirrored to the
authenticated user's Firestore (`Phase 6`, see `../ROADMAP.md`).

## Entity (`AuthUser`)

| Field | Type |
|-------|------|
| `userId` | String |
| `name` | String |
| `email` | String |
| `photoUrl` | String? |

## Repository port (`AuthRepository`)

```dart
abstract class AuthRepository {
  Stream<AuthUser?> watchAuthState(); // null = signed out
  AuthUser? get currentUser;
  Future<Either<Failure, AuthUser>> signInWithGoogle();
  Future<void> signOut();
}
```

Implementations:
- `LocalAuthRepository` *(now)* — placeholder: reports signed-out, refuses sign-in
  with a clear message. Lets the bloc/UI be exercised with no Firebase project.
- `FirebaseAuthRepository` *(deferred)* — drops in behind the same port once
  `firebase_options.dart` is provided.

## State machine (`AuthBloc`)

```
AuthUnknown → AuthAuthenticated(user) | AuthUnauthenticated(message?)
events: AuthStarted, AuthSignInRequested, AuthSignOutRequested
```

`AuthStarted` subscribes to `watchAuthState`; a sign-in failure re-emits
`AuthUnauthenticated` carrying the message. The bloc is not yet wired into the
router (constraint 3 below) — no login screen until the Firebase impl lands.

## Design constraints (so v1 stays compatible)

1. v1 writes everything against a local profile id constant. When auth lands, that
   id becomes the `userId`; a one-time local→cloud migration uploads existing data.
2. All repositories already scope by an owner id (today a constant) → no schema
   change needed when `userId` becomes real.
3. Until Phase 6, `AuthBloc` is absent; the router goes straight to `/dashboard`.

## Open questions

- Sign-in providers beyond Google? (Apple for iOS later.)
- Conflict resolution strategy for multi-device edits (last-write-wins vs merge).
