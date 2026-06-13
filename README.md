# Investanco

Personal investment portfolio tracker built with Flutter (Android + Web).

You register **what you own** (ticker + quantity + average price) across institutions
(Nubank, Avenue, …). Investanco **automatically tracks** current value, profit/loss
and performance using **public market-data APIs** — no broker login, no scraping, no
aggregator. The only manual data is your holdings, which change rarely; everything
that changes daily (prices, FX, indices) is fetched automatically.

Landing page: https://guilhermeeng99.github.io/Investanco/ — live web app: https://guilhermeeng99.github.io/Investanco/app/

## Why this design

| Data | Changes when | Source |
|------|--------------|--------|
| Holdings (what/how much you own) | you buy or sell (rare) | manual entry |
| Value / profit / performance | every day | public APIs (automatic) |

Firestore is the source of truth; Drift (SQLite) is a local cache that the app
rebuilds at sign-in and renders immediately while it refreshes in the background.
Google sign-in is required. See `docs/specs/overview.md`.

## Features

- **Holdings & records** — institutions, assets and transactions (buy/sell/dividend),
  one at a time or via **bulk CSV import** (separate Assets/Transactions flows with a
  review screen). See `docs/specs/csv_import.md`.
- **Automatic valuation** — per-holding market value, profit/loss and return, with
  **fixed-income accrual** (CDI/Selic/prefixed/IPCA+) modeled as dated cash flows.
  See `docs/specs/valuation.md`.
- **Allocation (Investimentos, the landing tab)** — user-defined classes with target
  %, real-vs-target comparison and a rebalancing plan. See `docs/specs/allocation.md`.
- **Daily snapshots** of total value/invested/P-L for history. See `docs/specs/snapshots.md`.
- **Cloud sync** — Firebase Auth (Google) + Firestore as the source of truth, with a
  single-owner lock. See `docs/specs/cloud_sync.md`.

## Tech stack

Flutter · flutter_bloc · get_it · go_router · Drift · dio · fl_chart · slang ·
dartz · Firebase (Auth + Firestore) · very_good_analysis.

## Data sources (all public)

| Source | Used for | Auth |
|--------|----------|------|
| brapi.dev | BR equities, FIIs, ETFs, BDRs | free token |
| CoinGecko | Crypto prices (BRL/USD) | none |
| Finnhub | US equities/ETFs (Avenue) | free token |
| Tesouro Direto | Tesouro Direto bond prices | none |
| BCB SGS | CDI / Selic / IPCA series (fixed income) | none |
| AwesomeAPI | USD→BRL FX | none |

## Getting started

```bash
flutter pub get
dart run build_runner build   # generate Drift code
dart run slang                # generate i18n strings
```

### API tokens (build-time)

`FINNHUB_TOKEN` (US equities) and `BRAPI_TOKEN` (BR market) are baked in via
dart-define — never entered in-app. Copy the example and fill in free-tier keys:

```bash
cp env.example.json env.json   # env.json is gitignored
```

### Run

```bash
flutter run -d chrome --dart-define-from-file=env.json   # web
flutter run -d <device> --dart-define-from-file=env.json # android
```

> Web uses Drift over sqlite3 WASM (`web/sqlite3.wasm` + `web/drift_worker.dart.js`).

Google sign-in is required: the UI is gated behind Firebase Auth and Firestore is
the source of truth (the local Drift cache is rebuilt at sign-in). Reads render from
the cache immediately, then refresh in the background.

## Development

```bash
flutter analyze   # must be zero issues
flutter test      # all tests must pass
```

Conventions, architecture and the post-change checklist: [`CLAUDE.md`](CLAUDE.md).
Feature specs (entity contracts, business rules, state machines): [`docs/specs/`](docs/specs/).
