# Spec: Dashboard

The home screen. Renders the consolidated portfolio from cached data instantly,
then refreshes quotes in the background.

## What it shows

1. **Header**: total equity (BRL), total unrealized P/L (value + %), day change.
2. **Allocation**: donut chart by asset class and a toggle by institution (fl_chart).
3. **Holdings list**: per holding — asset, institution, quantity, current value,
   P/L (value + %), stale badge if price old.
4. **Evolution**: line chart of portfolio value over time (from snapshots, see
   `snapshots.md`).
5. **Sync status**: last refresh time, manual refresh button, error banner.

## State machine (`DashboardCubit`)

A `Cubit` (no events). It subscribes to the transactions/assets/institutions streams
on creation and recomputes on every emission.
```
DashboardLoading
DashboardLoaded(portfolio, assetsById, institutionsById, snapshots, isRefreshing, lastSyncAt?)
DashboardError()               // only when a source stream errors with no data
```
Rules:
1. On first stream data → emit `Loaded` from cache immediately, then auto-trigger one
   background `refresh()` (guarded by `_autoRefreshed`).
2. During refresh, keep `Loaded` with `isRefreshing = true` (never blank the screen).
3. A failing refresh keeps the last `Loaded` (cached data stays on screen).
4. The allocation by-class / by-institution toggle is **presentation-only**: both
   breakdowns are precomputed in `PortfolioValuation` (`byClass`, `byInstitution`);
   the cubit does no filtering.

## Business rules

1. Values come from `ValuationService` (`valuation.md`); the dashboard never does math.
2. Empty portfolio → onboarding empty state (add institution → asset → transaction).
3. Currency formatting via `formatCurrency()`; all labels via slang.

## Edge cases

- All prices stale → header shows values with a global "prices may be outdated" note.
- Foreign holdings without FX → excluded from total with a warning chip.
- Very large lists → `ListView.builder`, charts computed off the build method.
