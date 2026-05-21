# Spec: Cloud Sync (Firestore source of truth) *(Phase 6.3)*

Keeps the portfolio consistent across every device signed into the same account.
**Firestore is the source of truth**; the local Drift database is a cache. Every
write goes to Firestore first (write-through); at sign-in the local cache is
rebuilt from Firestore so creates, edits **and** deletes made on any device are
reflected. Mirrors the reference project `financo`. Not to be confused with
`sync.md` (market-data refresh).

> **Online-first.** Because the cloud is authoritative, a write needs
> connectivity: an offline `save`/`delete` fails (surfaced to the user) instead
> of being cached locally, since the next authoritative sync would discard a
> row that never reached Firestore. This is a deliberate trade-off to match
> financo and guarantee cross-device consistency.

## Scope

Mirrored (user-owned): `institutions`, `assets`, `transactions`, `snapshots`.
Not mirrored: `quotes` (derived cache, refreshed from market APIs) and `settings`
(device-local). Both are preserved across an authoritative sync.

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
  /// Authoritative pull: rebuild local from Firestore for [userId].
  Future<Either<Failure, Unit>> sync(String userId);

  /// Permanently delete the user's mirrored data — both the Firestore
  /// collections and the local Drift rows (settings kept). No undo.
  Future<Either<Failure, Unit>> clear(String userId);

  /// Wipe only the local Drift rows (keep Firestore + settings). Sign-out.
  Future<void> resetLocal();
}
```

`FirestoreSyncService.sync` fetches every mirrored collection, then calls
`AppDatabase.replaceMirroredData` to swap the local tables in one transaction.
There is **no push**: writes already reached Firestore live.

## Port (`RemoteMirror`)

```dart
abstract class RemoteMirror {
  Future<void> upsert(String collection, String id, Map<String, dynamic> json);
  Future<void> delete(String collection, String id);
}
```

`FirestoreRemoteMirror` writes `users/{uid}/{collection}/{id}` for the current
user (no-op when signed out) and **throws on failure** so the repository can
surface it. Repositories take it as an optional dependency defaulting to
`NoopRemoteMirror`, so tests skip remote writes.

## When sync runs

- **Live, per change (write-through)**: every repository write (`save`/`delete`
  of an institution, asset or transaction) writes to Firestore via `RemoteMirror`
  **before** caching to Drift. A remote failure aborts the write (local cache
  untouched) and returns a `Failure`. Snapshots are derived, so their mirror is
  best-effort (a failure is swallowed; the next sync rebuilds them).
- **Authoritative, at sign-in**: `StartupCubit` blocks on `SyncService.sync(userId)`
  on the splash before the user enters, rebuilding the local cache from Firestore.
  A failure surfaces as `StartupError` with a retry. No manual re-sync UI.

## Reconciliation

Authoritative pull, `sync(userId)`:

1. Fetch every mirrored collection from Firestore.
2. `replaceMirroredData`: in one transaction, delete the local mirrored tables
   (children before parents) and re-insert the fetched rows. `quotes` and
   `settings` are left untouched.

The local cache ends identical to the cloud. Deletes propagate for free (a row
absent from Firestore is absent locally after the rebuild); no tombstones needed.
Convergent across devices for a single user.

### Known limitations (follow-ups)

- **Offline writes**: not supported (online-first, see note above). A future
  follow-up could queue writes locally and replay them.
- **No live propagation to an open device**: another signed-in device reflects a
  change only on its next `sync` (sign-in / splash), not in real time. Firestore
  `snapshots()` listeners would be needed for that — neither app does it yet.
- **No field-level LWW**: the last full-document write to Firestore wins.

## Sign-out

On explicit sign-out the local Drift rows are wiped (`SyncService.resetLocal`,
called by `AuthBloc`), keeping settings. The cloud is the source of truth, so the
same user's next sign-in pulls everything back. This prevents a **cross-account
leak**: without it, account B signing in on the same device would inherit A's
leftover rows. Best-effort — a failed wipe doesn't block sign-out.

## Edge cases

- Signed out → no sync; local data wiped (cloud keeps the data; re-login restores
  it). A device with no one signed in holds no portfolio rows.
- Offline / permission error at sign-in → `StartupError` on the splash with a
  retry; the (stale) local cache is left intact until the sync succeeds.
- First sign-in on a fresh device → the authoritative pull populates an empty
  local cache.
