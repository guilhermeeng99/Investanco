# Spec: Snapshots

Daily record of total portfolio value, so the app can chart performance over time
even if a data source later becomes unavailable. Our history is **our** data.

## Entity contract

The domain `Snapshot` is a value object (Equatable, no id) — all money in base currency:

| Field | Type | Invariant |
|-------|------|-----------|
| `date` | DateTime (local midnight) | one snapshot per day |
| `totalValue` | Money | portfolio value at capture |
| `totalInvested` | Money | cost basis at capture |
| `totalPL` | Money | unrealized P/L at capture |

The Drift row (`SnapshotRow`) additionally carries `id` (the `yyyy-MM-dd` day key,
used for idempotent upsert and as the Firestore doc id) and `currency`. There is no
`byClass`/`createdAt` — the snapshot stores totals only.

## Business rules

1. **Idempotent per day**: the row id is `yyyy-MM-dd`, so writing again the same day
   **updates** it (`insertOnConflictUpdate`).
2. Written by `DashboardCubit._writeSnapshot()` at the end of a refresh — not by a
   separate sync component (see `dashboard.md`; `sync.md` is deferred).
3. Never written when the portfolio has no fresh-priced open position (avoids garbage
   points): `_writeSnapshot` skips unless at least one held position is non-stale.
4. Mirrored to Firestore per write via `RemoteMirror` and in bulk at sign-in (see
   `cloud_sync.md`).

## Repository contract

```dart
abstract class SnapshotRepository {
  // Writes (or updates) today's snapshot — idempotent per day.
  Future<Either<Failure, Unit>> upsertToday({
    required Money totalValue,
    required Money totalInvested,
    required Money totalPL,
  });

  // Snapshots within the inclusive date range, oldest first.
  Future<Either<Failure, List<Snapshot>>> range(DateTime from, DateTime to);
}
```

The Drift impl mirrors each write to Firestore via the same guarded path as the
other repositories: a local or cloud write failure surfaces as a `CacheFailure`
(the dashboard treats a snapshot write/read as best-effort).

## Edge cases

- App opened multiple times a day → single snapshot, updated each time.
- Gap days (app not opened) → no snapshot; chart interpolates/connects gaps.
- Clock change / timezone → snapshot date uses local date at capture.
