# Spec: Transactions

The events that build a position: buys, sells, dividends. Transactions are the
**source of truth**; holdings are derived from them (`holdings.md`).

> The entity is named `AssetTransaction` (not `Transaction`) to avoid clashing with
> Drift's generated `Transaction` class.

## Entity contract

| Field | Type | Invariant |
|-------|------|-----------|
| `id` | String (uuid) | immutable |
| `institutionId` | String | FK → Institution |
| `assetId` | String | FK → Asset |
| `kind` | `TransactionKind` | `buy`, `sell`, `dividend` |
| `quantity` | double | > 0 (for buy/sell); ignored for dividend |
| `unitPrice` | Money (minor units, native currency) | ≥ 0 |
| `fees` | Money | ≥ 0, default 0 |
| `amount` | Money | for dividend: total received; else derived `quantity*unitPrice` |
| `date` | DateTime | not in the future |
| `notes` | String? | optional |
| `createdAt` / `updatedAt` | DateTime | audit |

## Business rules

1. `buy`/`sell` require `quantity > 0` and `unitPrice ≥ 0`.
2. A `sell` cannot exceed the quantity held **at its date** →
   `ValidationFailure(code: oversell)`, enforced in `TransactionRepositoryImpl`
   (so the form and the CSV import are both guarded). `oversellsTimeline` re-runs
   the whole (asset, institution) position, so a backdated buy edit that strands a
   later sell is caught too.
3. `dividend` carries `amount` only; does not change quantity.
4. `date` cannot be in the future → `ValidationFailure(code: futureTransactionDate)`
   in the repository (the form's date picker also caps `lastDate` at today).
5. Editing/deleting a transaction re-derives the affected holding (see 6.1 in overview).
6. Native currency is the **asset's** currency; consolidation to BRL happens at
   valuation time, not storage time.
7. **Fixed income** uses transactions as cash flows: `buy` = deposit (aplicação),
   `sell` = redemption (resgate). Enter `quantity = 1` and `unitPrice = amount`;
   `quantity` is only a placeholder (a count) — the valuation reads each
   transaction's `amount` and `date` as a dated cash flow (see `valuation.md` §2),
   so partial redemptions value correctly. Keeping `quantity = 1` also means that
   *should* the oversell guard (rule 2) be implemented, it won't block a redemption
   that includes accrued yield.

## Repository contract

```dart
abstract class TransactionRepository {
  Stream<List<AssetTransaction>> watchAll();                  // newest first
  Stream<List<AssetTransaction>> watchByAsset(String assetId); // oldest first (for holdings)
  Future<Either<Failure, Unit>> save(AssetTransaction tx);    // create or update (upsert)
  Future<Either<Failure, Unit>> delete(String id);
}
```

## State machine (`TransactionsCubit`)

`TransactionsLoading → TransactionsLoaded(transactions, assets, institutions, institutionFilter)
| TransactionsError(failure)`. The cubit merges three streams (transactions, assets,
institutions) so the list can render asset/institution labels. The form is a plain
`StatefulWidget` (`transaction_form_sheet.dart`) — there is no separate form cubit;
it validates locally and calls `add`/`edit`, which return a `Failure?`.

### Institution filter

`TransactionsLoaded` carries an optional `institutionFilter` (an institution id;
`null` = all). `setInstitutionFilter(id?)` updates it and re-emits. The state exposes
`visibleTransactions` = `transactions` narrowed to that institution (the raw
`transactions` stays the full list so the page can still tell "no transactions at
all" apart from "none match the filter"). The filter survives stream re-emits.
If the filtered institution is deleted, the filter resets to `null` (its chip would
otherwise vanish, stranding the user on an empty list). The page only shows the
filter bar when there is more than one institution — nothing to filter otherwise.

## Validation

Rules 2 (oversell) and 4 (future date) are enforced in `TransactionRepositoryImpl`
before any write — `oversell_check.dart`'s `oversellsTimeline` for the former, a
date check for the latter — returning a `ValidationFailure` with a `ValidationCode`
(`oversell` / `futureTransactionDate`). The form maps the code to localized copy via
`validationMessage`; the CSV import sorts rows oldest-first (buys before sells on a
tie) so a valid file's sells always follow their covering buys.

## Edge cases

- Oversell (sell > held at date) → blocked with `ValidationFailure(oversell)`.
- Backdated buy that makes a later sell invalid → blocked too (the whole position
  timeline is re-validated on every buy/sell save).
- Zero-fee, zero-price (e.g. bonus shares) → allowed.
- Filter set to an institution that has no transactions → empty list with a
  "no results" hint; the filter bar stays so the user can clear it.
- Filtered institution deleted → filter resets to all (see state machine).
