# Spec: Profile & Settings

User preferences. In v1 (no auth) this is a single local profile; in Phase 6 it
binds to the authenticated user.

## Entity contract

| Field | Type | Default |
|-------|------|---------|
| `baseCurrency` | `Currency` | `brl` |
| `themeMode` | `ThemeMode` | `system` |
| `staleThresholdMinutes` | int | 60 |
| `syncIntervalMinutes` | int | 5 |
| `locale` | String | `pt` |

Stored in a single-row Drift table (`settings`) keyed by a constant id.

## Business rules

1. `baseCurrency` change re-runs valuation (re-consolidates all foreign holdings).
2. `themeMode`/`locale` apply immediately (`ThemeCubit` / `AppLocaleCubit`).
3. Market-data tokens are **not** in settings — they are build-time dart-define
   (see `quotes.md`), so there is no token UI and nothing token-related to persist.
4. Colour palette (separate light + dark catalogs) is picked in Preferences and
   persisted per device (SharedPreferences); it mutates `AppColors.*` and the two
   palette cubits rebuild the theme.
5. Locale offers a **System** option (`null` = follow device) alongside PT/EN.
6. **Clear my data** permanently wipes the user's cloud (Firestore) **and** local
   (Drift) data via `SyncService.clear`; device settings are kept. No undo.
7. On web, a **Get the app** action downloads the bundled `investanco.apk`.

Device-local preferences (theme mode, palette, locale) live outside the synced
data — they are per-device and not mirrored to Firestore.

## State machine (`ProfileCubit`)

`ProfileLoading → ProfileLoaded(settings) | ProfileError`. Mutations emit updated
`ProfileLoaded`.

## Edge cases

- First run → defaults seeded.
