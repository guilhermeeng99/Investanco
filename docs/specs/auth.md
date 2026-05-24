# Spec: Auth *(Phase 6 — Firebase auth + required login gate)*

Authentication is **required**: the app is gated behind Google sign-in. The whole
UI sits below an auth guard — an unauthenticated user only ever sees the startup
splash and the login carousel. Drift stays the local source of truth; signing in
mirrors it to the user's Firestore (`cloud_sync.md`).

## Goal

Firebase Auth + Google Sign-In as the entry gate, mirroring financo's flow:
splash → (signed out) login carousel → (signed in) sync → Investimentos (the
landing tab).

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

- `FirebaseAuthRepository` — platform-split Google sign-in (mirrors financo):
  a Firebase popup on web, native `google_sign_in` on mobile. The native mobile
  flow is **required**: `signInWithProvider` on Android opens a Custom Tab web
  redirect through `firebaseapp.com/__/auth/handler`, which fails with "missing
  initial state" in storage-partitioned browsers (the Android WebView/Custom Tab).
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
3. Sign-in always forces the Google account chooser. Firebase's `signOut()`
   clears only the Firebase session, not Google's, so without this a post-sign-out
   sign-in would silently re-authenticate the previous account and block switching
   users. Platform-split:
   - **Web** — the OAuth `prompt=select_account` custom parameter on
     `GoogleAuthProvider`, passed to `signInWithPopup`.
   - **Mobile** — `signOut()` also calls `GoogleSignIn.signOut()` (non-fatal, on a
     best-effort basis) so the next `authenticate()` shows the chooser fresh.
4. `google_sign_in` is initialised once at startup via `GoogleSignIn.initialize()`,
   **mobile-only**: on web Firebase's `signInWithPopup` owns the Google Identity
   Services lifecycle, so initialising there conflicts with it (and calling
   `GoogleSignIn.signOut()` on web would throw `StateError`). On Android the server
   client id is read from `google-services.json` (its `oauth_client` web entry),
   so the release SHA-1/SHA-256 must be registered in the Firebase console.
5. **Single-owner access.** Sign-in is restricted to an owner allow-list in
   `FirebaseAuthRepository`: a non-authorized Google account is signed back out
   and the attempt is rejected with `UnauthorizedFailure`, surfaced as a localized
   message (`AuthUnauthenticated` → `t.auth.unauthorizedAccount`). This is a
   client-side UX gate so the wrong account gets a clear error instead of an empty
   app; `firestore.rules` pins the same e-mail server-side (the real enforcement).
   A true auth-layer block (Firebase Auth blocking functions) would need Identity
   Platform/GCIP enabled on the project.

## Open questions

- Sign-in providers beyond Google? (Apple for iOS later.)
- Conflict resolution for multi-device edits (last-write-wins vs merge).
