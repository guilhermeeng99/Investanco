# Investanco — Roadmap

Living tracker of what's **done**, **in progress** and **planned**. Updated as work
proceeds. The source of truth for product/feature contracts is `docs/specs/`.

**Legend:** ✅ done · 🔨 in progress · ⬜ todo · 🧊 deferred / optional

---

## Phase 0 — Foundation & conventions

| # | Item | Status |
|---|------|--------|
| 0.1 | Flutter project bootstrap (`investanco`, `com.guiga.investanco`, android+web) | ✅ |
| 0.2 | Dependency stack (bloc, get_it, go_router, drift, dio, fl_chart, slang, dartz) | ✅ |
| 0.3 | `analysis_options.yaml` — very_good_analysis + generated-code excludes | ✅ |
| 0.4 | `CLAUDE.md` — project conventions (mirrors financo) | ✅ |
| 0.5 | `docs/specs/*` — feature specs | ✅ |
| 0.6 | `.github/workflows/deploy.yml` — CI/CD (web + APK → gh-pages) | ✅ |
| 0.7 | App shell: theme (M3 light/dark), router, DI container | ✅ |
| 0.8 | Core: `Money`, failures, formatter, Drift database, IdGenerator (dio client → Phase 2) | ✅ |
| 0.9 | slang i18n bootstrap (pt-BR base) | ✅ |
| 0.10 | App compiles, web build OK, `analyze` 0 issues, `test` 6/6 green | ✅ |

---

## Phase 1 — Core domain & local persistence (offline-first)

| # | Item | Status |
|---|------|--------|
| 1.1 | `Institution` entity + Drift table + repo + cubit + CRUD UI | ✅ |
| 1.2 | `Asset` entity (ticker, kind, market, currency) + table + repo + cubit + UI | ✅ |
| 1.3 | `Transaction` (buy/sell/dividend) + table + repo + cubit + form | ✅ |
| 1.4 | `Holding` derivation (qty + weighted avg cost, realized P/L, dividends) | ✅ |
| 1.5 | Unit tests (avg price, sells, dividends, edge cases) | ✅ |

---

## Phase 2 — Quotes & valuation (the "automatic" part)

| # | Item | Status |
|---|------|--------|
| 2.1 | `QuoteDataSource` interface + brapi adapter (BR equities/FII/ETF/crypto) | ✅ |
| 2.2 | Yahoo Finance adapter (US equities/ETF — Avenue) | ✅ |
| 2.3 | Tesouro Direto adapter (bond prices) | 🧊 |
| 2.4 | BCB SGS adapter (CDI/Selic/IPCA) + fixed-income accrual valuation | 🧊 |
| 2.5 | `FxDataSource` (AwesomeAPI USD→BRL) | ✅ |
| 2.6 | Quote cache (Drift) + repository (cached-first, refresh) | ✅ |
| 2.7 | `ValuationService`: market value, profit, return %, BRL consolidation | ✅ |
| 2.8 | Unit tests for valuation formulas | ✅ |

---

## Phase 3 — Dashboard & visualization

| # | Item | Status |
|---|------|--------|
| 3.1 | Dashboard: total equity, total profit, day change | ⬜ |
| 3.2 | Allocation chart (by asset class / by institution) — fl_chart | ⬜ |
| 3.3 | Per-holding list with live value & P/L | ⬜ |
| 3.4 | Pull-to-refresh + manual sync button | ⬜ |

---

## Phase 4 — History & snapshots

| # | Item | Status |
|---|------|--------|
| 4.1 | `Snapshot` table — daily portfolio value persisted locally | ⬜ |
| 4.2 | Snapshot writer (runs on refresh, one per day, idempotent) | ⬜ |
| 4.3 | Evolution line chart (portfolio value over time) | ⬜ |

---

## Phase 5 — Sync orchestration & polish

| # | Item | Status |
|---|------|--------|
| 5.1 | `SyncBloc` — refresh all quotes/FX/indices, retry+backoff, status | ⬜ |
| 5.2 | Refresh on app open + periodic timer (market hours) | ⬜ |
| 5.3 | Theming polish, empty states, error states | ⬜ |
| 5.4 | Full pt-BR i18n pass | ⬜ |

---

## Phase 6 — Cloud sync (multi-device) 🧊

| # | Item | Status |
|---|------|--------|
| 6.1 | Firebase project + `firebase_options.dart` (user-provided config) | 🧊 |
| 6.2 | Firebase Auth + Google Sign-In | 🧊 |
| 6.3 | Firestore mirror of Drift + offline reconciliation | 🧊 |

---

## Phase 7 — Distribution 🧊

| # | Item | Status |
|---|------|--------|
| 7.1 | Android keystore + signing config + CI secrets | 🧊 |
| 7.2 | Firebase App Distribution (testers) | 🧊 |
| 7.3 | gh-pages live web build — https://guilhermeeng99.github.io/Investanco/ | ✅ |

---

## Phase 8 — Auto-import adapters (reduce manual entry) 🧊

| # | Item | Status |
|---|------|--------|
| 8.1 | `Pluggy` adapter behind `PositionSource` (auto-import Nubank holdings) | 🧊 |
| 8.2 | Avenue CSV import (statement upload → parse → transactions) | 🧊 |
| 8.3 | Avenue email/IMAP statement ingestion | 🧊 |
| 8.4 | B3 Área do Investidor scraper adapter (fragile — evaluate) | 🧊 |

> Architecture keeps all position sources behind a `PositionSource` port, so these
> are additive — manual entry (Phase 1) remains the robust default.

---

## Decisions log

- **Flutter over Python backend** — mirrors the author's existing stack (financo),
  fully client-side feasible via public REST APIs, easiest to maintain & deploy.
- **Offline-first (Drift) before Firebase** — app runs and is testable with no
  cloud credentials; cloud sync is additive (Phase 6).
- **Manual holdings + automatic pricing** — most robust model; no broker auth,
  scraping or aggregator dependency. Aggregators are optional (Phase 8).
- **Money as integer minor units** — avoid floating-point drift in financial math.
