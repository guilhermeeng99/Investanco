# Spec: Profile & Settings

User preferences. In v1 (no auth) this is a single local profile; in Phase 6 it
binds to the authenticated user.

## Entity contract

`AppSettings` (Equatable + `copyWith`):

| Field | Type | Default |
|-------|------|---------|
| `themeMode` | `AppThemeMode` (`system`/`light`/`dark`) | `system` |
| `baseCurrency` | `Currency` | `brl` |

Stored in a single-row Drift table (`settings`, id always 0). `AppThemeMode` is a
domain enum mapped to Flutter's `ThemeMode` in the presentation layer
(`theme_mode_mapper.dart`). Stale threshold and refresh cadence are **not** settings
(they are constants/deferred); locale and colour palette live outside `AppSettings`
in their own device-local cubits (see rules 4–5).

## Business rules

1. `baseCurrency` is persisted but fixed to BRL in v1 (no switcher UI yet);
   consolidation always targets BRL.
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

`ProfileCubit extends Cubit<AppSettings>` — the state **is** the settings object
(no separate loading/loaded/error states). It starts at `const AppSettings()`
defaults; `load()` emits the persisted settings; `setThemeMode(mode)` persists,
applies live via `ThemeCubit`, and emits the updated settings. Locale, palette,
sign-out and "clear my data" are driven by their own cubits/services, not this one.

## Edge cases

- First run → defaults seeded.
