# Spec: Transactions

The events that build a position: buys, sells, dividends. Transactions are the
**source of truth**; holdings are derived from them (`holdings.md`).

## Entity contract

| Field | Type | Invariant |
|-------|------|-----------|
| `id` | String (uuid) | immutable |
| `institutionId` | String | FK → Institution |
| `assetId` | String | FK → Asset |
| `kind` | `TransactionKind` | `buy`, `sell`, `dividend` |
| `quantity` | Decimal | > 0 (for buy/sell); ignored for dividend |
| `unitPrice` | Money (minor units, native currency) | ≥ 0 |
| `fees` | Money | ≥ 0, default 0 |
| `amount` | Money | for dividend: total received; else derived `quantity*unitPrice` |
| `date` | DateTime | not in the future |
| `notes` | String? | optional |
| `createdAt` / `updatedAt` | DateTime | audit |

## Business rules

1. `buy`/`sell` require `quantity > 0` and `unitPrice ≥ 0`.
2. A `sell` cannot exceed the quantity held **at its date** → else `ValidationFailure`.
3. `dividend` carries `amount` only; does not change quantity.
4. `date` cannot be in the future.
5. Editing/deleting a transaction re-derives the affected holding (see 6.1 in overview).
6. Native currency is the **asset's** currency; consolidation to BRL happens at
   valuation time, not storage time.

## Repository contract

```dart
abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> watchAll();
  Future<Either<Failure, List<Transaction>>> watchByAsset(String assetId);
  Future<Either<Failure, Unit>> create(Transaction tx);
  Future<Either<Failure, Unit>> update(Transaction tx);
  Future<Either<Failure, Unit>> delete(String id);
}
```

## State machine (`TransactionsCubit`)

`TransactionsInitial → Loading → Loaded(list) | Error(failure)`.
Form: `TransactionFormCubit` → `Editing → Submitting → Success | Invalid(field) | Failure`.

## Edge cases

- Oversell (sell > held at date) → blocked.
- Backdated buy that makes a later sell invalid → validation re-runs across the
  timeline; conflicting edit is rejected with the offending tx id.
- Zero-fee, zero-price (e.g. bonus shares) → allowed.
