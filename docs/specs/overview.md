# Spec: Overview (Master)

The product vision, domain model, data sources and the math that powers everything.
Feature specs in this folder refine each area; this is the entry point.

---

## 1. Vision

A personal app where the user **registers what they own** across institutions
(e.g. Nubank, Avenue) and the app **automatically tracks** current value,
profit/loss and performance over time using **public market-data APIs**.

Reference benchmark: [Kinvo](https://kinvo.com.br/) — but Kinvo relies on an
aggregator (Open Finance via BTG) to auto-import positions. Investanco deliberately
uses the **manual-holdings + automatic-pricing** model: it needs no broker login,
no scraping and no paid aggregator, which makes it robust and free for one user.

### Key insight

Two kinds of data with very different change frequency:

| Data | Changes when | Source |
|------|--------------|--------|
| **Holdings** (what/how much you own) | you buy or sell (rare) | manual entry |
| **Value / profit / performance** | every day | public APIs (automatic) |

The daily-changing part is fully automated. The manual part is low-frequency.

---

## 2. Scope

### In scope (v1)
- Register institutions, assets and transactions (buy/sell/dividend) — one at a
  time, or in bulk via CSV import (`csv_import.md`).
- Derive holdings (quantity + average cost) from transactions.
- Auto-fetch prices: BR equities/FIIs/ETFs/BDRs, US equities/ETFs, Tesouro Direto,
  crypto; auto-fetch FX (USD→BRL) and indices (CDI/Selic/IPCA).
- Value fixed income (CDB/RDB/LCI/LCA) by rate + index accrual.
- Dashboard: total equity, profit, allocation, per-holding P/L.
- Daily snapshots → portfolio evolution chart.
- Offline-first reads from a local cache (Drift); writes require connectivity.

### Non-goals (v1)
- Placing orders / trading.
- Tax reports (IR / DARF) — possible later.
- Real-time tick streaming (we use delayed/EOD-ish quotes; refresh on demand).
- Multi-user / social features.

### Done since v1 (see ROADMAP)
- Firebase cloud sync (multi-device) + Google sign-in gate (Phases 6–7).
- Bulk CSV import — separate Assets and Transactions imports, each with a review
  screen before committing. See `csv_import.md`.

### Still deferred
- Live broker auto-import (Pluggy / scraper) — bulk CSV import shipped instead;
  live integrations would need broker auth/aggregators.
- Tax reports (IR / DARF); FIFO cost basis; base-currency switcher.
- Hardened refresh orchestration (retry/backoff, periodic timer) — see `sync.md`.

---

## 3. Glossary

- **Institution** — where assets are custodied (Nubank, Avenue, a broker).
- **Asset** — a tradable instrument (PETR4, AAPL, "Tesouro IPCA+ 2029", a CDB).
- **Asset kind** — `stockBr`, `fiiBr`, `etfBr`, `bdrBr`, `stockUs`, `etfUs`,
  `crypto`, `treasury`, `fixedIncome`, `fund`, `cash`.
- **Transaction** — a buy, sell or dividend event on an asset at an institution.
- **Holding** — net position of one asset (quantity + average cost), derived from
  its transactions.
- **Quote** — latest known unit price of an asset in its native currency.
- **Snapshot** — total portfolio value (in BRL) recorded on a given date.

---

## 4. Domain model (relationships)

```
Institution 1───* Transaction *───1 Asset
                      │
                      ▼ (derived)
                   Holding ──(priced by)──> Quote / index accrual
                      │
                      ▼ (aggregated daily)
                   Snapshot
```

Detailed entity contracts live in each feature spec:
`institutions.md`, `assets.md`, `transactions.md`, `holdings.md`,
`quotes.md`, `valuation.md`, `dashboard.md`, `snapshots.md`, `sync.md`,
`profile.md`, `auth.md`, `startup.md`.

---

## 5. Data sources

All public. Each wrapped behind a project-owned interface (Clean Architecture
boundary). Endpoints and response contracts: `quotes.md`.

| Source | Base | Used for | Auth |
|--------|------|----------|------|
| brapi.dev | `https://brapi.dev/api` | BR equities, FII, ETF, BDR | free token |
| CoinGecko | `https://api.coingecko.com/api/v3` | crypto prices (BRL/USD) | none |
| Finnhub | `https://finnhub.io/api/v1` | US equities/ETF (Avenue) | free token |
| Tesouro Direto | `https://www.tesourodireto.com.br/json/.../treasury/getMarket` | bond prices | none |
| BCB SGS | `https://api.bcb.gov.br/dados/serie/bcdata.sgs.{code}/dados` | CDI(12)/Selic(11)/IPCA(433) | none |
| AwesomeAPI | `https://economia.awesomeapi.com.br/json/last/USD-BRL` | USD→BRL FX | none |

### Asset kind → pricing strategy

| Asset kind | Pricing source | Strategy |
|------------|----------------|----------|
| stockBr, fiiBr, etfBr, bdrBr | brapi | direct quote |
| stockUs, etfUs | Finnhub | direct quote × FX |
| crypto | CoinGecko | direct quote in asset currency (BRL or USD; × FX if USD) |
| treasury | Tesouro Direto | direct unit price by bond name |
| fixedIncome (CDB/RDB/LCI/LCA) | BCB SGS index | accrual from purchase by contracted rate |
| fund | manual NAV (v1) | user-updated unit price |
| cash | none | face value (× FX if foreign) |

---

## 6. Valuation math

Money is stored as **integer minor units** (cents) to avoid float drift. Quantities
may be fractional (US stocks, crypto) → stored as `double`.

### 6.1 Average cost (weighted)
On **buy**: `newAvg = (qtyOld*avgOld + qtyBuy*priceBuy + fees) / (qtyOld + qtyBuy)`
On **sell**: average cost **unchanged**; realized P/L = `(priceSell - avg) * qtySell - fees`.
On **dividend**: increases realized income; does not change quantity/avg.

### 6.2 Market value (native currency)
`marketValue = quantity * currentUnitPrice`

### 6.3 Profit / return (per holding)
```
unrealizedPL  = marketValue - (quantity * avgCost)
returnPct     = unrealizedPL / (quantity * avgCost)        # guard div-by-zero
totalPL       = unrealizedPL + realizedPL + dividends
```

### 6.4 BRL consolidation
For a holding in foreign currency:
`valueBrl = marketValue * fxRate(currency → BRL)`

### 6.5 Fixed-income accrual (CDB/RDB/LCI/LCA)
Valued from dated **cash flows** (a buy = deposit, a sell = redemption), not a single
principal. By linearity of daily accrual:
```
currentValue = Σ amount_f * accrualFactor(flow_f.date → today)
factor("110% of CDI") = ∏ (1 + dailyIndexRate_d * indexPercent)  over business days d since the flow date
```
IPCA-linked, per flow: `(1 + ipcaAccumulated) * (1 + fixedSpread)^(businessDays/252)`.
Index series come from BCB SGS. See `valuation.md` for the precise formulas/tests.

### 6.6 Day change
`dayChange = (currentUnitPrice - previousClose) * quantity`, summed across holdings,
converted to BRL.

---

## 7. Currency

- **Base currency**: BRL (configurable in `profile`).
- Holdings keep their **native** currency; consolidation converts via latest FX.
- FX rate cached locally; refreshed on sync. Stale FX is flagged in the UI.

---

## 8. Architecture

Clean Architecture, feature-first (see `CLAUDE.md`). **Firestore is the source of
truth**; Drift is a local cache rebuilt at sign-in (writes mirror through
`RemoteMirror`). Market data (quotes/FX/indices) fills a separate derived cache. The
UI always renders cached data immediately, then refreshes. See `cloud_sync.md`.

---

## 9. Phasing

See `../ROADMAP.md`. Build order: foundation → domain+DB → quotes+valuation →
dashboard → snapshots → sync/polish → (cloud) → (auto-import).
