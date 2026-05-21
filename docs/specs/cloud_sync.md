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

  /// Permanently delete the user's mirrored data — both the Firestore
  /// collections and the local Drift rows (settings kept). No undo. Backs the
  /// profile "clear my data" action.
  Future<Either<Failure, Unit>> clear(String userId);
}
```

`FirestoreSyncService` reads/writes Drift rows directly (bulk) and uses batched
Firestore writes. Pull upserts each remote doc into Drift via
`insertOnConflictUpdate`; push batches every local row up.

## When sync runs

- **Live, per change**: every repository write (`save`/`delete` of an institution,
  asset, transaction or snapshot) mirrors that single document to Firestore via
  `RemoteMirror` — cloud tracks local edits immediately. Best-effort: offline /
  transient failures are swallowed (Drift stays the source of truth) and the
  startup sync reconciles them next launch.
- **Bulk, at sign-in**: `StartupCubit` blocks on `SyncService.sync(userId)` on the
  splash (pull then push) before the user enters, catching up anything the live
  mirror missed (e.g. offline edits). A failure surfaces as `StartupError` with a
  retry. There is no manual re-sync UI (mirrors financo).

## Port (`RemoteMirror`)

```dart
abstract class RemoteMirror {
  Future<void> upsert(String collection, String id, Map<String, dynamic> json);
  Future<void> delete(String collection, String id);
}
```

`FirestoreRemoteMirror` writes `users/{uid}/{collection}/{id}` for the current
user (no-op when signed out), swallowing errors. Repositories take it as an
optional dependency defaulting to `NoopRemoteMirror`, so tests skip remote writes.

## Reconciliation (v1)

Union upsert: pull then push. On a true conflict the remote wins during pull, then
the merged local set is pushed. Convergent for a single user across devices.

### Known v1 limitations (follow-ups)

- **Offline deletes**: an online delete propagates immediately via `RemoteMirror`;
  a delete made **offline** isn't pushed, so the next startup pull can resurrect it
  (the bulk push only upserts). Edge case, acceptable for v1.
- **No field-level LWW**: last full-document write wins; `transactions.updatedAt`
  is not yet used to resolve per-record conflicts.

## Sign-out

On explicit sign-out the local Drift rows are wiped (`SyncService.resetLocal`,
called by `AuthBloc`), keeping settings. The cloud is the source of truth, so the
same user's next sign-in pulls everything back. This prevents a **cross-account
leak**: without it, account B signing in on the same device would merge A's
leftover rows and the bulk push would upload them to B's Firestore. Best-effort —
a failed wipe doesn't block sign-out.

## Edge cases

- Signed out → no sync; local data wiped (cloud keeps the data; re-login restores
  it). A device with no one signed in holds no portfolio rows.
- Offline / permission error → `StartupError` on the splash with a retry; local
  data intact, retried on the next sign-in.
- First sign-in on a fresh device → pull populates an empty local DB.
