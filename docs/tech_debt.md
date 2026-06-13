# Tech Debt & Maintenance Backlog

Known, deliberately-deferred maintenance items. Product-feature deferrals live in
`specs/overview.md` §2; this file is for dependency risk and test-coverage gaps.
Last reviewed: 2026-06-13 (deep review).

## Dependencies

- **`dartz` (0.10.1) is unmaintained** — last pub.dev release ~4 years ago, no
  Dart-3-era update. The whole error-handling convention (`Either<Failure, T>`)
  rests on it, so this is load-bearing. It still works on the current SDK.
  - **Decision needed:** keep (accept the risk, it's stable and the API surface we
    use — `Either`/`Left`/`Right`/`fold`/`getOrElse` — is tiny) **or** migrate to
    `fpdart` (actively maintained, near drop-in `Either`, but a repo-wide refactor
    touching every repository, use case and cubit fold site).
  - **Recommendation:** keep for now; revisit only if it blocks an SDK upgrade.

- **`sqlite3_flutter_libs` (0.6.0+eol) is a no-op shim** — the `+eol` marker means
  the package "no longer does anything"; the app already rides the `sqlite3` 3.x
  native-assets path. The pin is currently harmless.
  - **Action:** the dependency can eventually be dropped from `pubspec.yaml`.
    Verify Android + web builds still bundle SQLite after removal before committing.

- **`package_info_plus` major (9 → 10) is currently BLOCKED** — 10.x requires
  `win32 ^6`, but `file_picker` (^11.0.2, the latest) pins `win32 ^5.9`, so the
  resolver rejects the upgrade. Not a code break — a transitive `win32` conflict.
  **Unblocks when** `file_picker` ships a release that moves to `win32 ^6`; bump
  both together then. Held at `^9.0.1` for now.

- **Routine bumps applied (2026-06-13):** firebase family (core 4.10.0, auth 6.5.2,
  cloud_firestore 6.5.0), drift + drift_dev 2.34.0 (lockstep, regenerated),
  slang + slang_flutter 4.16.0 (regenerated), go_router 17.3.0 — all in-constraint,
  analyze + 421 tests green. No security advisories outstanding.

## Test-coverage gaps (lower priority)

Logic paths are covered; these are the remaining thin spots, worst-first:

- `lib/core/database/app_database.dart` — Drift schema/migration path is untested
  (use drift's `SchemaVerifier`/migration test utilities). Matters because a bad
  migration corrupts the local cache.
- `lib/app/di/injection_container.dart` — no smoke test that the DI graph resolves;
  a missing registration only surfaces at runtime.
- `lib/app/theme/theme_cubit.dart`, `light_palette_cubit.dart`,
  `dark_palette_cubit.dart`, `lib/app/i18n/app_locale_cubit.dart` — persistence
  cubits with no tests (non-money, low risk, but they touch `shared_preferences`).
- `lib/core/format/date_formatter.dart`, `lib/core/format/initials.dart` — the only
  untested helpers in `core/format`.
