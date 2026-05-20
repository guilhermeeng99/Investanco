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

## State machine (`DashboardBloc`)

Events: `DashboardStarted`, `DashboardRefreshRequested`, `DashboardFilterChanged`.
States:
```
DashboardLoading
DashboardLoaded(PortfolioValuation, lastSyncAt, isRefreshing, filter)
DashboardError(failure)        // only when no cached data exists at all
```
Rules:
1. `Started` → emit `Loaded` from cache immediately, then trigger a background refresh.
2. During refresh, keep `Loaded` with `isRefreshing = true` (never blank the screen).
3. Refresh failure with cached data present → stay `Loaded`, show non-blocking banner.
4. `FilterChanged` (by class / by institution) recomputes aggregation locally.

## Business rules

1. Values come from `ValuationService` (`valuation.md`); the dashboard never does math.
2. Empty portfolio → onboarding empty state (add institution → asset → transaction).
3. Currency formatting via `formatCurrency()`; all labels via slang.

## Edge cases

- All prices stale → header shows values with a global "prices may be outdated" note.
- Foreign holdings without FX → excluded from total with a warning chip.
- Very large lists → `ListView.builder`, charts computed off the build method.
