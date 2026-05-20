# Spec: Snapshots

Daily record of total portfolio value, so the app can chart performance over time
even if a data source later becomes unavailable. Our history is **our** data.

## Entity contract

| Field | Type | Invariant |
|-------|------|-----------|
| `id` | String (uuid) | immutable |
| `date` | Date (no time) | unique per user — one snapshot per day |
| `totalValueBrl` | Money | portfolio value at capture |
| `totalInvestedBrl` | Money | cost basis at capture |
| `totalPLBrl` | Money | unrealized + realized + dividends |
| `byClass` | Map<AssetKind, Money> | allocation breakdown |
| `createdAt` | DateTime | audit |

## Business rules

1. **Idempotent per day**: writing a snapshot for an existing date **updates** it
   (last write of the day wins). Key on `date`.
2. Written automatically after a successful sync (see `sync.md`).
3. Never written when the whole portfolio is stale/unpriced (avoid garbage points).
4. Snapshots are local-only in v1 (mirrored to Firestore in Phase 6).

## Repository contract

```dart
abstract class SnapshotRepository {
  Future<Either<Failure, Unit>> upsertToday(PortfolioValuation valuation);
  Future<Either<Failure, List<Snapshot>>> range(DateTime from, DateTime to);
}
```

## Edge cases

- App opened multiple times a day → single snapshot, updated each time.
- Gap days (app not opened) → no snapshot; chart interpolates/connects gaps.
- Clock change / timezone → snapshot date uses local date at capture.
