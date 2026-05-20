# Spec: Auth *(deferred — Phase 6)*

Authentication is **not** required for v1 (offline-first, single local profile).
This spec defines the contract for when cloud sync is added, so the architecture
can accommodate it without rework.

## Goal

Firebase Auth + Google Sign-In, so the local Drift data can be mirrored to the
authenticated user's Firestore (`Phase 6`, see `../ROADMAP.md`).

## Planned entity

| Field | Type |
|-------|------|
| `userId` | String |
| `name` | String |
| `email` | String |
| `photoUrl` | String? |

## Planned state machine (`AuthBloc`)

```
AuthUnknown → AuthAuthenticated(user) | AuthUnauthenticated
events: AuthStarted, AuthSignInRequested, AuthSignOutRequested
```

## Design constraints (so v1 stays compatible)

1. v1 writes everything against a local profile id constant. When auth lands, that
   id becomes the `userId`; a one-time local→cloud migration uploads existing data.
2. All repositories already scope by an owner id (today a constant) → no schema
   change needed when `userId` becomes real.
3. Until Phase 6, `AuthBloc` is absent; the router goes straight to `/dashboard`.

## Open questions

- Sign-in providers beyond Google? (Apple for iOS later.)
- Conflict resolution strategy for multi-device edits (last-write-wins vs merge).
