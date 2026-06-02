# Spec: CSV Import

> Maps to the **`portfolio_import`** feature (`lib/features/portfolio_import/`); the
> spec keeps the `csv_import` name for the user-facing concept.

Two **separate** bulk imports, each on the page it belongs to and matching the
reference project (financo) which imports per entity:

- **Assets** (Assets page) — register a catalog of instruments.
- **Transactions** (Transactions page) — register movements against assets that
  already exist.

They are independent flows with their own example files, parsers, use cases and
review screens. Mirrors financo's CSV-import UX (intro dialog → download example
→ pick file → review → import). See also `assets.md`, `transactions.md`,
`institutions.md`.

## Why separate

Assets and transactions are different concepts. An asset carries classification
(`kind/market/currency`); a transaction carries a movement (`operation/quantity/
price/date`) and only *references* an asset. Importing them separately keeps each
file focused, and lets the transaction preview warn when a referenced asset isn't
registered yet — instead of silently fabricating one without a class.

## File format (both)

UTF-8 **or Latin-1/Windows-1252** (BR Excel exports; decoded by `csv_decoder`),
comma-separated, first line is a header. Columns are matched by name (accent- and
case-insensitive, order-free, extra columns ignored) via synonyms in
`csv_field_parsers.dart` (`mapCsvHeader`), so a Portuguese or English export both
work. Numbers accept BR (`1.234,56`) and EN (`1,234.56`) grouping; dates accept
`DD/MM/YYYY` or `YYYY-MM-DD`; quantities may be fractional.

### Assets CSV

| Logical column | Required | Default |
|----------------|----------|---------|
| ticker | yes | — |
| kind | yes | — |
| institution | yes | — |
| name | no | = ticker |
| market | no | by kind (`assetKindDefaults`) |
| currency | no | by kind |

`kind` accepts the enum name (`etfUs`) or a friendly label (`ETF (EUA)`,
`Ação BR`, `Cripto`, …), normalized.

### Transactions CSV

| Logical column | Required | Default |
|----------------|----------|---------|
| ticker | yes (must already exist) | — |
| institution | yes (must match the asset's institution) | — |
| quantity | yes (buy/sell) | — |
| price | yes (buy/sell) | — |
| amount | dividends only | — |
| operation | no | buy |
| fees | no | 0 |
| date | no | today |
| notes | no | — |

The transaction's money is denominated in the **referenced asset's currency**
(the file carries no currency column). The institution column is kept for import
safety and compatibility: it must match the institution already linked to the
referenced asset, and no institution is created by the transactions import.

## Entity contracts

`AssetImportRow` (Equatable): `ticker, name, kind, market, currency,
institutionName`.
`AssetImportPreview`: `rows` of `AssetImportPreviewRow {row, isNew}` with derived
`newCount`, `reusedCount` (distinct by ticker) and `withoutRowAt(i)`.
`AssetImportResult`: `assetsCreated`.

`TransactionImportRow` (Equatable): `ticker, institutionName, operation,
quantity, unitPriceMajor, feesMajor, amountMajor?, date, notes?`.
`TransactionImportPreview`: `rows` of `TransactionImportPreviewRow {row,
assetExists, institutionIsNew, assetHasInstitution, institutionMatchesAsset}`
with `transactionCount`, `newInstitutionCount` (kept for result compatibility),
`missingTickers`, `unlinkedTickers`, `institutionMismatchTickers`, `canImport`
(rows present and no blocked row) and `withoutRowAt(i)`.
`TransactionImportResult`: `transactionsCreated, institutionsCreated`.

## Use cases

`ImportAssetsCsvUseCase(AssetRepository, InstitutionRepository, IdGenerator)`:

```dart
Either<Failure, List<AssetImportRow>> parseRows(String csv);        // pure
Future<AssetImportPreview> previewRows(List<AssetImportRow>);       // read-only
Future<Either<Failure, AssetImportResult>> importRows(List<AssetImportRow>);
```

`ImportTransactionsCsvUseCase(AssetRepository, InstitutionRepository,
TransactionRepository, IdGenerator)`: same trio over the transaction types.

Business rules:

1. **Parse is pure** — no I/O. A malformed file (missing required column, bad
   number/date, unknown kind, empty, zero quantity, dividend without amount) →
   `ValidationFailure` with a row-tagged message; nothing is written.
2. **Assets**: matched by ticker (case-insensitive). A miss creates/reuses the
   institution by name, then creates the asset linked to that institution; a hit
   is reused (row fields ignored). Re-importing the same file doesn't duplicate.
3. **Transactions**: the asset **must already exist** (matched by ticker) and
   already have an institution. The CSV institution must match that linked
   institution; mismatches return
   `ValidationFailure(code: transactionInstitutionMismatch)`. One transaction
   per row.
4. Reads are guarded: a repository read error → `CacheFailure`. Persistence stops
   at the first write failure and returns it (counts reflect only what was
   created; partial data may remain).
5. Fully-blank lines are tolerated (skipped) during parse.

## UI flow

No bloc — dialogs/pages call the use cases from `get_it` directly. Every dialog
uses the shared `InvestancoDialog`; the intro/error dialogs and the sample
download live in `csv_import_dialog.dart` (`showCsvImportIntroDialog`,
`showCsvImportErrorDialog`, `downloadCsvSample`), shared by both imports.

`showAssetsCsvImportDialog(context)` / `showTransactionsCsvImportDialog(context)`:

1. **Intro** `InvestancoDialog` (CSV icon): *Select file* (primary) / *Download
   example* / *Cancel*.
2. *Download example* → writes the entity's sample
   (`investanco_assets_example.csv` / `investanco_transactions_example.csv`) →
   confirmation snackbar.
3. *Select file* → pick a `.csv` → decode → `parseRows`. On `Left` → error
   dialog. On `Right` → `previewRows` → push the review page.

### Review pages

- `AssetsImportPreviewPage` (`/import/assets/preview`): summary (items, new
  assets + `+N reused` caption) + per-row list (ticker, name,
  kind/currency/institution chips, `New` badge) + remove + submit. Pops an
  `AssetImportResult`.
- `TransactionsImportPreviewPage` (`/import/transactions/preview`): summary
  (transactions, blocked rows) + banners for missing assets, unlinked assets and
  institution mismatches that disable submit, + per-row list
  (operation/institution chips, `qty x price - date`, blocked rows flagged in
  error colour) + remove + submit. Pops a `TransactionImportResult`.

Both: removing rows recomputes the summary (and the transactions banner) live; a
blocking overlay covers the page during the import; on success the page pops the
result and the caller shows a snackbar; a failure keeps the page with an error
dialog. Shared leaf widgets in `import_preview_widgets.dart`.

Entry points: the **Assets** page opens the assets import; the **Transactions**
page opens the transactions import (both via the stacked `ImportAddFab`).

## Edge cases

- Transaction referencing an unknown ticker → flagged in the preview, import
  blocked until the row is removed or the asset is imported first.
- Transaction referencing an asset without `institutionId` → flagged in preview;
  edit the asset and choose the institution first.
- Transaction CSV institution different from the asset's institution → flagged
  in preview and rejected by `importRows`.
- Asset exists but the asset row repeats name/kind → existing asset reused.
- Unknown kind/currency/market token → `ValidationFailure` (kind) or default
  (market/currency).
- Empty file / header only / all-blank rows → `ValidationFailure`.
- Non-UTF-8 file (BR Excel) → decoded as Latin-1 so accents survive.
