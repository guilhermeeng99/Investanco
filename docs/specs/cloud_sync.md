# Spec: Cloud Sync (Firestore mirror) *(Phase 6.3)*

Mirrors the local Drift data to the signed-in user's Firestore so the portfolio
follows them across devices. Offline-first is preserved: **Drift stays the source
of truth**; Firestore is a sync target. Not to be confused with `sync.md` (market
data refresh).

## Scope

Mirrored (user-owned): `institutions`, `assets`, `transactions`, `snapshots`.
Not mirrored: `quotes` (derived cache) and `settings` (device-local).

## Firestore layout

```
users/{uid}/institutions/{id}
users/{uid}/assets/{id}
users/{uid}/transactions/{id}
users/{uid}/snapshots/{id}
```

Each document is the Drift row serialized via the generated `toJson()`; the doc id
is the row id. Security rules restrict every path to its owner (`request.auth.uid
== uid`).

## Service contract (`SyncService`)

```dart
abstract class SyncService {
  /// Pull remote → local, then push local → remote, for [userId].
  Future<Either<Failure, Unit>> sync(String userId);
}
```

`FirestoreSyncService` reads/writes Drift rows directly (bulk) and uses batched
Firestore writes. Pull upserts each remote doc into Drift via
`insertOnConflictUpdate`; push batches every local row up.

## State machine (`SyncCubit`)

```
SyncIdle → SyncInProgress → SyncSuccess(at) | SyncFailure(message)
```

Subscribes to `AuthRepository.watchAuthState`: on a signed-in user it syncs once;
`syncNow()` re-runs on demand (Settings button). No user → stays `SyncIdle`.

## Reconciliation (v1)

Union upsert: pull then push. On a true conflict the remote wins during pull, then
the merged local set is pushed. Convergent for a single user across devices.

### Known v1 limitations (follow-ups)

- **No deletion propagation**: a row deleted on one device reappears from remote.
- **No field-level LWW**: last full-document write wins; `transactions.updatedAt`
  is not yet used to resolve per-record conflicts.
- **Manual/at-sign-in only**: no continuous push on every local edit.

## Edge cases

- Signed out → no sync; local data untouched.
- Offline / permission error → `SyncFailure`, local data intact, retried next sign-in
  or via the button.
- First sign-in on a fresh device → pull populates an empty local DB.
