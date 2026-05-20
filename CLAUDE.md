# Investanco — Project Conventions

Personal investment portfolio tracker built with Flutter. Supports Android and Web.

Consolidates holdings the user manually registers (or imports) across institutions
(e.g. **Nubank**, **Avenue**) and **automatically tracks** their current value,
profit/loss and performance using **public market-data APIs** — no broker login,
no scraping, no aggregator required.

> Reference project for conventions: `financo` (same author). Investanco mirrors its
> architecture, spec-driven workflow and tooling, adapted to investment tracking.

---

## Why this design

The only data that needs manual entry is **what you own** (ticker + quantity +
average price), which changes rarely (only when you buy/sell). Everything that
changes daily — prices, FX, indices — is fetched **automatically** from public
APIs. This makes the app robust (depends only on stable public endpoints, no
auth/captcha/aggregator) and free to run. See `docs/specs/overview.md`.

---

## Architecture

**Clean Architecture** with feature-first organization:

```
lib/
├── app/
│   ├── assets/   # App assets: i18n/ (slang sources), images/
│   ├── di/       # get_it service locator
│   ├── router/   # go_router config + shell
│   ├── theme/    # AppColors, AppTypography, AppTheme, ThemeCubit
│   └── widgets/  # Shared design-system widgets (Investanco* + helpers)
├── core/         # Shared: database, errors, network, extensions, utils
├── features/     # Feature modules (each with data/domain/presentation)
└── gen/          # Generated code (i18n strings in gen/i18n)
```

Translation sources live in `lib/app/assets/i18n/` (`pt.i18n.json` base + `en.i18n.json`); slang generates `lib/gen/i18n/strings.g.dart`. This mirrors financo.

Each feature follows:

* `domain/` — entities, repository interfaces, use cases
* `data/` — models, datasources, repository implementations
* `presentation/` — cubits/blocs, pages, widgets

---

## Code Style

* Functions: 5–25 lines. Split if longer.
* Files: ideally under 400–600 lines.
* One responsibility per function/module (SRP).
* Prefer small, composable widgets over large ones.

### Naming

* Names must be specific and intention-revealing.
* Avoid generic names like `data`, `manager`, `handler`.
* Prefer names that are searchable and unique within the codebase.

### Control Flow

* Prefer early returns over nested conditionals.
* Maximum 2 levels of indentation.

---

## Comments

* Write **WHY**, not WHAT.
* Preserve important context and decisions.
* Do not remove meaningful comments during refactors.
* Public APIs must include intent, parameters and a usage example.

---

## Key Technologies

| Aspect               | Detail                                                                  |
| -------------------- | ----------------------------------------------------------------------- |
| **State management** | flutter_bloc (Cubits for simple state, Blocs for event-driven)          |
| **DI**               | get_it (service locator in `lib/app/di/injection_container.dart`)       |
| **Routing**          | go_router (declarative, path-based, shell route)                         |
| **Local database**   | Drift (SQLite — source of truth, offline-first)                          |
| **Remote sync**      | Firebase Firestore + Firebase Auth + Google Sign-In *(planned, Phase 6)* |
| **Market data**      | dio HTTP client behind `QuoteDataSource` / `FxDataSource` interfaces     |
| **Charts**           | fl_chart (allocation + portfolio evolution)                             |
| **Error handling**   | dartz `Either<Failure, T>` pattern                                       |
| **Linting**          | very_good_analysis (strict)                                             |
| **i18n**             | slang (sources in `lib/app/assets/i18n/`, generated in `lib/gen/i18n/`)  |
| **Theme**            | Light + Dark Material 3, custom `AppColors` / `AppTheme`                 |
| **Currency**         | BRL base (Real) via `intl`; multi-currency holdings converted via FX     |

---

## External Data Sources

All market data comes from **public** APIs. Each is wrapped behind a
project-owned interface (never call an HTTP client directly from domain/UI).

| Source            | Used for                                              | Auth        |
| ----------------- | ---------------------------------------------------- | ----------- |
| **brapi.dev**     | BR equities, FIIs, ETFs, BDRs, crypto, indices      | free token  |
| **Yahoo Finance** | US equities/ETFs (Avenue holdings)                  | none        |
| **Tesouro Direto**| Tesouro Direto bond prices                          | none        |
| **BCB SGS**       | CDI / Selic / IPCA series (fixed-income valuation)  | none        |
| **AwesomeAPI**    | USD→BRL FX rate (consolidation to BRL)              | none        |

See `docs/specs/quotes.md` for endpoints, contracts and the asset→source map.

---

## Commands

```bash
flutter test                              # Run all tests
flutter test test/features/holdings/      # Run feature tests
flutter analyze                           # Static analysis (must be zero issues)
flutter run -d chrome                      # Run the app (web)
dart run build_runner build   # Generate Drift code
dart run slang                            # Generate i18n
```

> Per the user's global config, prefix shell commands with `rtk` (see RTK section).

---

## Post-Change Checklist

After every code change:

1. Run `dart run slang` if any i18n JSON was modified
2. Run `dart run build_runner build` if Drift tables/DAOs changed
3. Run `flutter analyze` — **zero** errors, warnings and info-level issues
4. Run `flutter test` — all tests must pass
5. Never add `// ignore` without clear justification

---

## Spec-Driven Development

Every feature MUST have a spec at `docs/specs/<feature>.md` before writing new
code or tests.

### Workflow

1. Write or update the spec (business rules, contracts, state machines)
2. Write tests based on the spec
3. Implement or modify code to pass the tests
4. Update the spec if requirements change

### Spec Structure

* Entity contract (fields, types, invariants)
* Business rules (numbered, testable)
* Repository contract (methods, parameters, return types)
* State machines (cubit/bloc states and transitions)
* Edge cases

---

## Testing Rules

* Every new use case must have tests
* Every bug fix must include a regression test
* Tests must follow F.I.R.S.T (Fast, Independent, Repeatable, Self-validating, Timely)

### Test Structure

* One test file per source file (mirrors `lib/`)
* Use `bloc_test` for cubit/bloc testing
* Use factories for test data — never hardcode entities
* Mock at boundaries: repositories for cubits, datasources for repositories

---

## Harness Engineering

Test infrastructure lives in `test/harness/`:

* `mocks.dart` — centralized mock declarations (mocktail)
* `helpers.dart` — shared test setup and utilities
* `factories/` — test data factories per entity

---

## Dependencies

* Depend on abstractions, not implementations
* Inject dependencies via constructor or DI
* External libraries (dio, drift, firebase) MUST be wrapped behind project-owned interfaces

---

## Code Conventions

* Entities use `Equatable` and provide `copyWith`
* Failures are sealed classes (`ServerFailure`, `CacheFailure`, `NetworkFailure`, …)
* Use cases are single-method classes with `call()` operator
* Models extend entities and handle serialization
* All repository methods return `Future<Either<Failure, T>>`
* Use package imports (`package:investanco/...`)
* Apply `const` constructors wherever possible
* Money is stored as integer **minor units** (cents) — never as `double`. See `Money` in `core`.

### UI & Formatting

* Every user-facing string via slang (`t.section.key`) — never hardcode
* Monetary values formatted with `formatCurrency()` — never display raw numbers

---

## State Management

* **Bloc** for complex event-driven logic (Sync, Dashboard)
* **Cubit** for simpler state (Institutions, Assets, Transactions, Holdings, Profile, Startup)

### Rules

* UI must not contain business logic
* Cubits/Blocs orchestrate, UseCases execute logic
* State must be immutable

---

## Performance

* Avoid unnecessary rebuilds (use `const`, selectors, split widgets)
* Lists must use lazy builders (`ListView.builder`, etc.)
* Cache quotes locally (Drift); never block UI on network — show cached, refresh in background
* Batch quote requests (brapi accepts comma-separated tickers)

---

## Firestore Schema *(planned — Phase 6)*

```
users/{userId}                          → name, email, photoUrl, baseCurrency, createdAt
institutions/{id}                       → userId, name, type, createdAt
assets/{id}                             → userId, ticker, name, kind, market, currency
transactions/{id}                       → userId, institutionId, assetId, kind, quantity, unitPrice, fees, date, notes, createdAt
snapshots/{id}                          → userId, date, totalValueBrl, totalCostBrl, byClass
```

Guidelines: always scope queries by `userId`; avoid unbounded queries; prefer
batched writes; mirror Drift schema 1:1.

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it.
If not, it passes through unchanged. RTK is always safe to use. This applies even
inside command chains:

```bash
# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## Common commands

```bash
rtk flutter test        # Test failures only
rtk git status          # Compact status
rtk git diff            # Compact diff
rtk git log             # Compact log
rtk ls <path>           # Tree format, compact
rtk grep <pattern>      # Search grouped by file
rtk gain                # Token savings statistics
```

Passthrough works for ALL subcommands, even those not explicitly listed.
<!-- /rtk-instructions -->
