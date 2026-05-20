# Spec: Sync

Orchestrates refreshing all market data (quotes, FX, indices), recomputing the
portfolio, and writing the daily snapshot. Built for reliability: retries,
backoff, partial success, and never blocking the UI.

## Responsibilities

1. Collect all active assets (quantity > 0).
2. Route each to its `QuoteDataSource`; batch per source.
3. Refresh FX rates for every non-base currency in use.
4. Refresh index series needed by fixed-income holdings.
5. Recompute `PortfolioValuation`; persist quotes; upsert today's snapshot.

## State machine (`SyncBloc`)

Events: `SyncRequested(manual)`, `SyncTick` (periodic).
States:
```
SyncIdle(lastSyncAt)
SyncInProgress(progress)        // 0..1, partial sources may already be done
SyncSuccess(lastSyncAt)
SyncPartial(lastSyncAt, failedSources)   // some sources failed, cache served
SyncFailure(failure)            // total failure (network down) — cache still shown
```

## Reliability rules

1. **Retry with backoff** per source: 3 attempts, exponential (e.g. 0.5s, 1s, 2s),
   jittered. A failing source does not abort the others (`SyncPartial`).
2. **Idempotent**: re-running sync produces the same cache state; safe to spam.
3. **Cache-served**: the UI always has data; sync only updates it.
4. **Rate-limit aware**: on HTTP 429, honor backoff, reduce batch frequency.
5. **No background isolate in v1**: sync runs on app open + a periodic in-app timer
   during market hours + manual trigger. (Android `workmanager` is Phase 7.)

## Triggers

- On app foreground / dashboard open (if `lastSyncAt` older than `minInterval`).
- Manual refresh button / pull-to-refresh.
- Periodic timer (e.g. every 5 min) while app is foregrounded and market open.

## Edge cases

- Offline → `SyncFailure`, cached values shown, banner "offline".
- One source down (e.g. Yahoo) → `SyncPartial`, only US holdings flagged stale.
- Snapshot skipped if portfolio fully unpriced (see `snapshots.md` rule 3).
