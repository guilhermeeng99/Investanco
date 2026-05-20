# Spec: Profile & Settings

User preferences. In v1 (no auth) this is a single local profile; in Phase 6 it
binds to the authenticated user.

## Entity contract

| Field | Type | Default |
|-------|------|---------|
| `baseCurrency` | `Currency` | `brl` |
| `themeMode` | `ThemeMode` | `system` |
| `brapiToken` | String? | null (uses free-tier limited access) |
| `staleThresholdMinutes` | int | 60 |
| `syncIntervalMinutes` | int | 5 |
| `locale` | String | `pt` |

Stored in a single-row Drift table (`settings`) keyed by a constant id.

## Business rules

1. `baseCurrency` change re-runs valuation (re-consolidates all foreign holdings).
2. `brapiToken` is optional; when set, more tickers/quota are available.
3. `themeMode`/`locale` apply immediately (ThemeCubit / AppLocaleCubit).
4. Secrets (token) are never logged.

## State machine (`ProfileCubit`)

`ProfileLoading → ProfileLoaded(settings) | ProfileError`. Mutations emit updated
`ProfileLoaded`.

## Edge cases

- Invalid brapi token → quote calls fail gracefully (cache served), settings unaffected.
- First run → defaults seeded.
