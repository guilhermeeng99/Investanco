# Spec: Dashboard

The home screen. Renders the consolidated portfolio from cached data instantly,
then refreshes quotes in the background.

## What it shows

1. **Institution filter** (top): horizontal chips — "All" + each institution that
   holds value — scoping the whole screen (header, allocation, positions) to one
   institution. Default "All". Shown only when more than one institution holds value.
2. **Header**: total equity (BRL), total unrealized P/L (value + %), day change.
   When part of the (visible) portfolio is dollar-denominated, a secondary line
   shows that slice's value **in USD** (`byCurrency`), so the user sees the dollar
   of what is dollar — not only the consolidated BRL.
3. **Allocation**: donut chart by asset class and a toggle by institution (fl_chart).
4. **Holdings list**: per holding — asset, institution, quantity, current value
   (BRL, plus the native USD value for dollar holdings), unrealized P/L (value + %),
   stale badge if price old. Sorted by return % descending (best performers first).
5. **Sync status**: last refresh time, manual refresh button, error banner.

Daily snapshots are still recorded (see `snapshots.md`) but not charted on the
dashboard — there is no net-worth-evolution card.

## State machine (`DashboardCubit`)

A `Cubit` (no events). It subscribes to the transactions/assets/institutions streams
on creation and recomputes on every emission.
```
DashboardLoading
DashboardLoaded(portfolio, assetsById, institutionsById, snapshots, isRefreshing, lastSyncAt?)
DashboardError()               // only when a source stream errors with no data
```
`DashboardLoaded` also carries `institutionFilter` (an institution id; null = all).
`portfolio` is always the **full** portfolio; `visiblePortfolio` applies the filter
via `PortfolioValuation.forInstitution`, which re-aggregates totals/allocation from
the matching holdings. Snapshots are always written from the full `portfolio`.

Rules:
1. On creation the cubit **warm-starts** FX + index series from the durable
   `MarketCacheStore`, then on first stream data emits `Loaded` from cache
   immediately and auto-triggers one background `refresh()` (guarded by
   `_autoRefreshed`). `refresh({force})` skips the network when the held quotes
   are within `quoteFreshness`; the refresh button / pull-to-refresh pass
   `force: true`. So a reopened app shows the previous values at once, and the
   dashboard + allocation screens don't both re-fetch (see `quotes.md` rules 6–7).
2. During refresh, keep `Loaded` with `isRefreshing = true` (never blank the screen).
3. A failing refresh keeps the last `Loaded` (cached data stays on screen).
4. The allocation by-class / by-institution toggle is **presentation-only**: both
   breakdowns are precomputed in `PortfolioValuation` (`byClass`, `byInstitution`);
   the cubit does no filtering.
5. `setInstitutionFilter(id?)` re-emits with the new filter (no recompute). A filter
   pointing at an institution that no longer holds value resets to all (its chip is
   gone). The onboarding empty state keys off the **full** portfolio, never the
   filter, so filtering to a bank with no positions shows a "no positions" hint with
   the filter bar intact — not the onboarding CTA.

## Business rules

1. Values come from `ValuationService` (`valuation.md`); the dashboard never does math.
2. Empty portfolio → onboarding empty state whose CTA targets the next missing
   step via `DashboardLoaded.nextSetupStep`: no institution → "add institution"
   (pushes Institutions); has institutions but no asset → "new asset" (Registros
   tab → Ativos, `/records?tab=assets`); has both but no open position → "new
   transaction" (Registros tab → Lançamentos, `/records?tab=transactions`).
3. Currency formatting via `formatCurrency()`; all labels via slang.

## Edge cases

- All prices stale → header shows values with a global "prices may be outdated" note.
- Foreign holdings without FX → excluded from total with a warning chip.
- Very large lists → `ListView.builder`, charts computed off the build method.
