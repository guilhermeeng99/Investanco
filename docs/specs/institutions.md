# Spec: Institutions

Where assets are custodied: Nubank, Avenue, a broker, a bank. Pure organizational
grouping — used to filter/segment holdings and (later) to attach an auto-import
source.

Accessed as a **pushed sub-page** (`/institutions`, root navigator, back chip via
`InvestancoAppBar(showBack: true)`) reached from **Profile → Your data** and the
dashboard empty-state CTA — not a primary nav tab, since holdings change rarely.

## Entity contract

| Field | Type | Invariant |
|-------|------|-----------|
| `id` | String (uuid) | immutable |
| `name` | String | non-empty, ≤ 60 chars, unique per user |
| `kind` | `InstitutionKind` | `bank`, `broker`, `internationalBroker`, `crypto`, `other` |
| `currency` | `Currency` | default `brl`; `usd` for Avenue |
| `createdAt` | DateTime | set on create |

`Institution` uses `Equatable` + `copyWith`.

## Business rules

1. Name is required, trimmed and unique per user (case-insensitive) — a duplicate
   returns `ValidationFailure(code: duplicateInstitutionName)`, enforced in
   `InstitutionRepositoryImpl`. (Length ≤60 is enforced by the Drift column.)
2. Deleting an institution with transactions is **blocked** — must reassign or
   delete its transactions first (return `InUseFailure`).
3. `kind` is informational; it does not change pricing (pricing is per-asset).
4. No seed defaults: the user adds institutions manually (the empty state suggests
   "Nubank, Avenue, …"). *(Earlier drafts specced auto-seeding; dropped so a fresh
   account starts clean and the user owns the list.)*

## Repository contract

```dart
abstract class InstitutionRepository {
  Stream<List<Institution>> watchAll();                       // reactive list, ordered by name
  Future<Either<Failure, Unit>> save(Institution institution); // create or update (upsert)
  Future<Either<Failure, Unit>> delete(String id);            // InUseFailure if referenced
}
```

## State machine (`InstitutionsCubit`)

`InstitutionsLoading → InstitutionsLoaded(list) | InstitutionsError`. The cubit
subscribes to `watchAll()`; mutations (`add`/`edit`/`remove`) return a `Failure?` and the
stream re-emits the updated list.

## Edge cases

- Duplicate name → `ValidationFailure` (rule 1), surfaced as a localized message.
- Delete while referenced → `InUseFailure`, list unchanged.
- Empty list → UI shows empty state with "add institution" CTA.
