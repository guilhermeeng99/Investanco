# Spec: Auth *(Phase 7 — login gate wired)*

Authentication is **required**: the app is gated behind Google sign-in. The whole
UI sits below an auth guard — an unauthenticated user only ever sees the startup
splash and the login carousel. Drift stays the local source of truth; signing in
mirrors it to the user's Firestore (`cloud_sync.md`).

## Goal

Firebase Auth + Google Sign-In as the entry gate, mirroring financo's flow:
splash → (signed out) login carousel → (signed in) sync → dashboard.

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

- `FirebaseAuthRepository` — Google sign-in via the firebase_auth provider flow
  (popup on web, native provider on mobile; no extra `google_sign_in` dep).
- `LocalAuthRepository` — placeholder for tests/no-Firebase; reports signed-out.

## State machine (`AuthBloc`)

```
AuthUnknown
  → AuthInProgress              (sign-in tapped, provider flow open)
  → AuthAuthenticated(user)
  | AuthUnauthenticated(message?)

events: AuthStarted, AuthSignInRequested, AuthSignOutRequested
```

- `AuthStarted` (dispatched once in `main`) subscribes to `watchAuthState`.
- `AuthSignInRequested` emits `AuthInProgress`, then `AuthAuthenticated` on
  success or `AuthUnauthenticated(message)` on failure. `AuthInProgress` drives
  the Google button spinner.
- The bloc is an app-wide singleton, provided at the root, consumed by the gate,
  the login page and Settings.

## Router gate (`resolveAuthRedirect`)

Pure function (testable) consumed by `GoRouter.redirect`, with
`refreshListenable` bound to `AuthBloc.stream`:

| `AuthBloc.state` | location | → redirect |
|------------------|----------|-----------|
| any | `/startup` | none (splash always allowed) |
| `AuthInProgress` | any | none (provider flow in flight) |
| `AuthUnknown` | off-startup | `/startup` (still resolving) |
| `AuthUnauthenticated` | not `/login` | `/login` |
| `AuthAuthenticated` | `/login` | `/startup` (sync before entering) |
| otherwise | — | none |

## Design constraints

1. All repositories scope by an owner id; on sign-in that id is the `userId`, so
   no schema change is needed (see `cloud_sync.md`).
2. Sign-out (`AuthSignOutRequested`) → `AuthUnauthenticated` → the gate routes
   back to `/login`.

## Open questions

- Sign-in providers beyond Google? (Apple for iOS later.)
- Conflict resolution for multi-device edits (last-write-wins vs merge).
