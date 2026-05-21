# Spec: CSV Import (bulk portfolio)

Bulk-register a whole portfolio from a single CSV — one row per **position**
(asset + the buy that created it). Designed for dumping a broker holdings list
(e.g. Avenue) without typing every asset and transaction by hand. Mirrors
financo's CSV-import UX (intro dialog → download example → pick file → import),
adapted to Investanco's domain. See also `assets.md`, `transactions.md`,
`institutions.md`.

## Why one combined row

A broker statement gives, per holding, the **ticker, quantity and average
price**. That is exactly one asset plus one buy transaction. So each CSV row
creates (or reuses) the institution, the asset, and **one buy** whose unit price
is the average price — reconstructing the invested cost. Current value and P/L
stay derived from live quotes (`quotes.md`), never imported.

## CSV format

UTF-8, comma-separated, first line is a header. Columns are matched by name
(accent- and case-insensitive, order-free, extra columns ignored) via synonyms,
so a Portuguese or English export both work.

| Logical column | Synonyms (normalized) | Required | Default |
|----------------|-----------------------|----------|---------|
| ticker | ticker, símbolo, symbol, código, code | yes | — |
| kind | kind, tipo, classe, class | yes | — |
| institution | institution, instituição, corretora, broker, conta, account | yes | — |
| quantity | quantity, quantidade, qtd, qty, shares, cotas | yes (buy/sell) | — |
| price | price, preço, preço médio, average, unit price, valor unitário | yes (buy/sell) | — |
| name | name, nome, descrição, description | no | = ticker |
| market | market, mercado | no | by kind |
| currency | currency, moeda | no | by kind |
| operation | operation, operação, transação, side, movimento | no | buy |
| fees | fees, taxas, custos | no | 0 |
| date | date, data | no | today |
| amount | amount, valor, total | dividends only | — |
| notes | notes, notas, observação, obs | no | — |

- **kind** accepts the enum name (`etfUs`) or a friendly label (`ETF (US)`,
  `ETF (EUA)`, `Ação US`, `Cripto`, `Renda fixa`, …), normalized.
- **market/currency** default to the usual pairing for the kind (US kinds →
  US/USD, BR kinds → BR/BRL, crypto → Global/USD) — see `assetKindDefaults`.
- **numbers** accept BR (`1.234,56`) and EN (`1,234.56`) grouping; a lone dot or
  comma is the decimal separator. Quantities may be fractional (`1.92012`).
- **dates** accept `DD/MM/YYYY` or `YYYY-MM-DD`.

## Entity contract

`PortfolioImportRow` (Equatable) — one parsed, not-yet-persisted row:
`ticker, name, kind, market, currency, institutionName, operation,
quantity, unitPriceMajor, feesMajor, amountMajor?, date, notes?`.

`PortfolioImportResult` (Equatable): `institutionsCreated, assetsCreated,
transactionsCreated`.

## Use case (`ImportPortfolioCsvUseCase`)

Depends on `AssetRepository`, `InstitutionRepository`, `TransactionRepository`,
`IdGenerator`. Three entry points (mirrors financo's preview/import split):

```dart
Either<Failure, List<PortfolioImportRow>> parseRows(String csv);   // pure
Future<Either<Failure, PortfolioImportResult>> importRows(List<PortfolioImportRow>);
Future<Either<Failure, PortfolioImportResult>> call(String csv);   // parse + import
```

Business rules:

1. **Parse is pure** — no I/O. A malformed file (missing required column, bad
   number/date, unknown kind, empty) → `ValidationFailure` with a row-tagged
   message; nothing is written.
2. **Idempotent references**: an institution is matched by name
   (case-insensitive); an asset by ticker (case-insensitive). A match is reused;
   a miss is **created** (institution kind defaults to `broker`, currency from
   the row/kind). So re-importing the same file does not duplicate assets or
   institutions — only appends transactions.
3. Each row creates **one** transaction: buy/sell use `quantity` + `unitPrice`
   (`amount = unitPrice × quantity`); dividend uses `amount` (quantity 0).
4. Persistence stops at the **first** repository failure and returns it (partial
   data may remain — the caller surfaces the error). Counts in the result reflect
   only what was created.
5. Fully-blank lines are tolerated (skipped) during parse; a non-blank but
   malformed row aborts parsing with a `ValidationFailure`.

## State / UI flow

No bloc — the dialog calls `ImportPortfolioCsvUseCase` from `get_it` directly.

`showPortfolioCsvImportDialog(context)`:

1. **Intro** `AlertDialog`: explains the format. Actions: *Cancel* /
   *Download example* / *Select file*.
2. *Download example* → writes a ready-to-edit sample CSV (web: browser download;
   mobile/desktop: save dialog) → confirmation snackbar.
3. *Select file* → pick a `.csv` (bytes) → `parseRows`. On `Left` → error dialog.
   On `Right` → **confirm** dialog (`Import N rows?`) → `importRows` → success
   snackbar (`X assets, Y transactions`) or error dialog.

Entry points: the **Assets** and **Transactions** pages each carry a stacked
floating action (`ImportAddFab`) — a small *import* button above the primary
*add* button (mirrors financo). Both open the same dialog; the import is a whole
portfolio (assets + transactions), so either tab is a valid place to start it.

## Edge cases

- Asset exists but the row repeats name/kind → existing asset reused; row fields
  ignored (no edit on import).
- Unknown kind / currency / market token → `ValidationFailure` (kind) or default
  (market/currency), never a silent wrong classification for kind.
- Empty file / header only → `ValidationFailure`.
- A US ETF with no Finnhub token still imports; it just shows cost basis until a
  quote loads (`quotes.md`).
