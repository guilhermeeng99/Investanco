# Spec: Assets

A tradable instrument the user owns. The asset's `kind` + `market` decide which
pricing source values it (see `quotes.md`).

## Entity contract

| Field | Type | Invariant |
|-------|------|-----------|
| `id` | String (uuid) | immutable |
| `ticker` | String | non-empty; symbol used to fetch quotes (e.g. `PETR4`, `AAPL`) |
| `name` | String | human label (e.g. "Petrobras PN") |
| `kind` | `AssetKind` | see enum below |
| `market` | `Market` | `br`, `us`, `global` |
| `currency` | `Currency` | native quote currency (`brl`, `usd`) |
| `institutionId` | String? | FK to `Institution`; nullable only for pre-v10 legacy rows until edited |
| `metadata` | `Map<String,String>` | kind-specific (e.g. fixed-income rate, index); defaults to `{}` |
| `createdAt` | DateTime | set on create |

```dart
enum AssetKind { stockBr, fiiBr, etfBr, bdrBr, stockUs, etfUs, crypto,
                 treasury, fixedIncome, fund, cash }
```

The enum keeps every kind (existing assets, CSV import and valuation depend on
them), but the asset form's Type picker only offers the kinds in active use —
`AssetKind.selectableKinds` = `etfUs, crypto, fixedIncome`. Re-add a kind there to
surface it again; no migration. Other kinds still deserialize and display when
present in stored data or an imported CSV.

## Business rules

1. `ticker` is required and uppercased. For `treasury`/`fixedIncome`/`fund`,
   `ticker` may be a synthetic id (no market symbol).
2. `institutionId` is required on save and must resolve to an existing
   institution. Legacy rows without it can load, but editing/saving the asset
   requires choosing the institution.
3. `(ticker, market)` is unique per user (ticker compared case-insensitively) — a
   duplicate returns `ValidationFailure(code: duplicateAsset)`, enforced in
   `AssetRepositoryImpl`.
4. `kind` determines `pricingStrategy` (resolved in `quotes.md`); `currency`
   defaults from `market` (`br→brl`, `us→usd`).
5. `metadata` for `fixedIncome` *should* carry `fiBasis` (a `FixedIncomeBasis` name:
   `cdi|selic|prefixed|ipca`) and `fiRate` (the contracted rate: `110` for 110% of
   CDI/Selic, or the absolute annual % for prefixed/IPCA+). Not enforced: the form
   writes both only when a rate is entered, so a `fixedIncome` asset with no rate is
   allowed and valued at cost until one is set. Keys are centralized in
   `FixedIncomeMetadata` (read/write). See `valuation.md`.
6. `metadata` for `treasury` contains the Tesouro bond canonical name used to match
   the Tesouro Direto API.

## Repository contract

```dart
abstract class AssetRepository {
  Stream<List<Asset>> watchAll();                    // reactive list, ordered by ticker
  Future<Either<Failure, Unit>> save(Asset asset);   // create or update (upsert)
  Future<Either<Failure, Unit>> delete(String id);   // InUseFailure if has transactions
}
```

## State machine (`AssetsCubit`)

`AssetsLoading → AssetsLoaded(list) | AssetsError`. The cubit subscribes to
`watchAll()`; mutations (`add`/`edit`/`remove`) return a `Failure?` for the form to
surface and let the stream re-emit the updated list.

## Edge cases

- Unknown ticker (quote not found) → asset still valid; UI flags "price unavailable".
- Duplicate `(ticker, market)` → `ValidationFailure` (rule 3), surfaced as a
  localized message.
- Legacy asset without `institutionId` → listed with a "no institution" chip;
  saving it requires selecting the institution first.
- Changing `kind`/`currency` after transactions exist → allowed but warns (pricing
  reinterpreted).
