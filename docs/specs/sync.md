# Spec: Market-data refresh *(orchestration mostly deferred)*

Refreshing all market data (quotes, FX, indices), recomputing the portfolio, and
writing the daily snapshot.

> **Naming note:** this spec is about **market-data** refresh, whose code lives in
> `lib/features/dashboard` + `lib/features/valuation`. The directory
> `lib/features/sync/` is a *different* concern — the Firestore **cloud** mirror,
> documented in `cloud_sync.md`. Don't map this spec to `lib/features/sync`.

> **Status:** there is **no** dedicated `SyncBloc`. The reliability design below
> (retry/backoff, partial-success states, periodic timer) was deferred. What
> actually ships is the shared `PortfolioPricingEngine`
> (`lib/features/valuation/presentation/portfolio_pricing_engine.dart`) composed by
> both `DashboardCubit` (`dashboard.md`) and `AllocationCubit` (`allocation.md`).

## What actually ships (`PortfolioPricingEngine` + the portfolio cubits)

The refresh/pricing logic was extracted into **`PortfolioPricingEngine`**, a module
each portfolio cubit composes (so the dashboard and allocation screens share the
rules but not the state). `DashboardCubit.refresh()` delegates to it
(`heldPositions` / `quotesAreFresh` / `refreshNetwork`) and owns only the daily
snapshot + institution filter. A single best-effort pass:

1. Derive holdings; collect held assets — open positions (`quantity > 0`) **plus**
   any fixed-income asset with cash flows even at zero net quantity (so its
   CDI/Selic/IPCA series is still fetched). See `heldAssetIds`.
2. `QuoteRepository.refresh(heldAssets)` — routes each asset to the first
   `QuoteDataSource` whose `supports()` is true; one attempt per source.
3. `_refreshIndices(...)` — fetches each BCB index series a fixed-income holding
   needs, from the earliest purchase date. Failures are ignored (holding shows cost
   until a series arrives).
4. If any held asset is foreign, fetch USD→BRL FX (`FxDataSource`).
5. Recompute `PortfolioValuation` via `ValuationService`; emit `DashboardLoaded`.
6. `_writeSnapshot()` — upsert today's snapshot when at least one position is
   fresh-priced (`snapshots.md`).

Triggers that exist: first screen load (auto, once per cubit) + manual
pull-to-refresh / refresh button (`force: true`). The UI always renders cached
data first; refresh never blanks the screen.

Two refinements keep cold start correct and avoid double work (see `quotes.md`
rules 6–7): each cubit **warm-starts** FX + index series from the durable
`MarketCacheStore` so a reopened app values everything from last-known data on
the first frame; and the auto-refresh is **skipped** when the held quotes are
fresher than `quoteFreshness` (15 min), so the dashboard and allocation screens
don't both re-fetch. `force` (manual refresh) always fetches.

## Deferred design (future `SyncBloc`)

If/when refresh is extracted from the dashboard, the target shape:

- **Retry with backoff** per source (3 attempts, exponential, jittered); a failing
  source does not abort the others (partial success).
- **Rate-limit aware** (HTTP 429 → honor backoff, reduce batch frequency).
- **Periodic timer** while foregrounded during market hours.
- States: `SyncIdle / SyncInProgress / SyncSuccess / SyncPartial(failedSources) /
  SyncFailure` — cache always served underneath.
- Android background refresh via `workmanager`.

## Edge cases (current behaviour)

- Offline → refresh is a no-op on the data; cached values stay on screen.
- One source down → only that source's holdings stay stale; others update.
- Snapshot skipped if no position is fresh-priced (`snapshots.md` rule 3).
