# Investanco

Personal investment portfolio tracker built with Flutter (Android + Web).

You register **what you own** (ticker + quantity + average price) across institutions
(Nubank, Avenue, …). Investanco **automatically tracks** current value, profit/loss
and performance using **public market-data APIs** — no broker login, no scraping, no
aggregator. The only manual data is your holdings, which change rarely; everything
that changes daily (prices, FX, indices) is fetched automatically.

Live web build: https://guilhermeeng99.github.io/Investanco/

## Why this design

| Data | Changes when | Source |
|------|--------------|--------|
| Holdings (what/how much you own) | you buy or sell (rare) | manual entry |
| Value / profit / performance | every day | public APIs (automatic) |

Drift (SQLite) is the offline-first source of truth; Firestore is an optional
multi-device mirror (Google sign-in). See `docs/specs/overview.md`.

## Tech stack

Flutter · flutter_bloc · get_it · go_router · Drift · dio · fl_chart · slang ·
dartz · Firebase (Auth + Firestore) · very_good_analysis.

## Data sources (all public)

| Source | Used for | Auth |
|--------|----------|------|
| brapi.dev | BR equities, FIIs, ETFs, BDRs, indices | free token |
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

Cloud sync is optional: the app runs fully offline with no Firebase credentials.

## Development

```bash
flutter analyze   # must be zero issues
flutter test      # all tests must pass
```

Conventions, architecture and the post-change checklist: [`CLAUDE.md`](CLAUDE.md).
Feature specs (entity contracts, business rules, state machines): [`docs/specs/`](docs/specs/).
Phase tracker: [`docs/ROADMAP.md`](docs/ROADMAP.md).
