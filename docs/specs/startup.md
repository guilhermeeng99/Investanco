# Spec: Startup

App bootstrap and the gate that decides the first screen. Keeps `main()` thin and
makes initialization testable.

## Responsibilities

1. Initialize DI (`get_it`), open the Drift database, load settings.
2. Run any pending migrations / first-run seeding (default institutions, §4 of
   `institutions.md`).
3. Decide initial route.

## State machine (`StartupCubit`)

```
StartupInitial → StartupInProgress → StartupReady(initialRoute) | StartupFailure(error)
```

Rules:
1. `StartupReady` resolves to `/dashboard` (v1, no auth). In Phase 6 it resolves to
   `/login` when unauthenticated.
2. `StartupFailure` (e.g. DB open error) → a retry screen; never a blank app.
3. Bootstrap must complete < 1s on a warm start (no network calls in startup;
   sync is triggered by the dashboard, not startup).

## Edge cases

- Corrupt local DB → surface `StartupFailure` with a "reset local data" option.
- First run → seed defaults, then `StartupReady`.
