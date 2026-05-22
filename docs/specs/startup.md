# Spec: Startup

App bootstrap and the **auth gate** that decides the first screen. Keeps `main()`
thin and makes the gate testable. Mirrors financo's startup flow.

## Responsibilities

1. `main()` initializes Firebase, DI (`get_it`), opens the Drift database and
   dispatches `AuthStarted` so the auth stream is live before the first frame.
2. `StartupPage` (the splash) drives `StartupCubit.initialize()`, which:
   waits for auth to resolve → if signed in, runs the cloud sync → then routes.
3. The router gate (see `auth.md`) blocks every route until authenticated.

## State machine (`StartupCubit`)

```
StartupInitial
  → StartupLoading(step: checkingAuth, progress: 0)
  → [unauthenticated] StartupUnauthenticated
  → [authenticated]   StartupLoading(step: syncing, progress: 0.3)
        → StartupAuthenticated(userId) | StartupError(failure)
```

`StartupStep` is an enum (`checkingAuth`, `syncing`) — the cubit never emits raw
copy, so the page maps it to a localized label (`t.startup.*`) and tests assert
the step, not the wording.

Rules:
1. `StartupAuthenticated` → the page routes to `/dashboard`.
2. `StartupUnauthenticated` → the page routes to `/login`.
3. The cubit blocks on `SyncService.sync(userId)` before `StartupAuthenticated`
   (financo-faithful: data is mirrored before the user enters). A sync failure
   surfaces `StartupError` with a retry that re-runs `initialize()`.
4. `_waitForAuth()` short-circuits when `AuthBloc.state` is already terminal
   (`AuthAuthenticated`/`AuthUnauthenticated`); otherwise it awaits the first
   terminal state on `AuthBloc.stream` (ignoring `AuthInProgress`).

## Edge cases

- Auth never resolves (no Firebase) → splash stays on `checkingAuth`; the gate
  keeps the user on `/startup`.
- Sync fails (offline / permission) → `StartupError`; local Drift data is intact,
  retry re-runs the sync.
- Authenticated cold start → `/startup` runs once, syncs, then `/dashboard`.
