# Spec: Quotes & Market Data

The "automatic" engine. Fetches unit prices, FX and indices from public APIs,
caches them locally (Drift), and exposes a uniform `Quote` regardless of source.

## Quote contract

| Field | Type | Notes |
|-------|------|-------|
| `assetId` | String | which asset |
| `unitPrice` | Money (native currency) | latest known price |
| `previousClose` | Money? | for day-change |
| `currency` | `Currency` | native currency of the price |
| `asOf` | DateTime | when the source reported it |
| `fetchedAt` | DateTime | when we cached it |
| `source` | `QuoteSource` | brapi / coingecko / finnhub / tesouro / bcb / manual |

## Data source interfaces (ports)

```dart
abstract class QuoteDataSource {
  bool supports(Asset asset);
  Future<Either<Failure, List<Quote>>> fetch(List<Asset> assets); // batch
}

abstract class FxDataSource {
  Future<Either<Failure, double>> rate(Currency from, Currency to);
}

abstract class IndexDataSource {
  /// Daily series for an economic index (CDI/Selic/IPCA) since [from].
  Future<Either<Failure, List<IndexPoint>>> series(EconomicIndex index, DateTime from);
}
```

## Adapters & endpoints

### brapi (BR equities, FII, ETF, BDR)
- `GET https://brapi.dev/api/quote/{TICKERS}?token={TOKEN}` (comma-separated, batched).
- Map: `regularMarketPrice → unitPrice`, `regularMarketPreviousClose → previousClose`.
- Token baked in at build time via `--dart-define=BRAPI_TOKEN=...`; never entered
  in-app. Empty token → free tier (limited tickers).
- **Not used for crypto.** brapi's free tier rejects `/v2/crypto`, and
  `/quote/BTC` resolves to a US ETF named "BTC" (Grayscale), not the coin — so
  crypto is priced by CoinGecko (below).

### CoinGecko (crypto)
- `GET https://api.coingecko.com/api/v3/simple/price?ids={IDS}&vs_currencies={CCYS}&include_24hr_change=true`.
  Keyless, batched (comma-separated ids + currencies in one call).
- Response is keyed by coin **id** (`bitcoin`), not ticker (`BTC`). Id resolution:
  `asset.metadata['coingeckoId']` → built-in ticker map → lowercased ticker.
- Price read in the asset's own currency (request `brl` and `usd` together, pick
  per asset). `previousClose` derived from `{ccy}_24h_change` (no absolute close).

### Finnhub (US equities/ETF — Avenue)
- `GET https://finnhub.io/api/v1/quote?symbol={SYMBOL}&token={TOKEN}`.
- Map: `c` (current) → `unitPrice`, `pc` (previous close) → `previousClose`. Currency `usd`.
- One request per symbol (free tier has no batch endpoint). Chosen over Yahoo/Stooq
  because Finnhub sends CORS headers, so it works from the web build. Token baked in
  via `--dart-define=FINNHUB_TOKEN=...`; empty token → US holdings show cost basis.

### Tesouro Direto (bonds)
- `GET https://www.tesourodireto.com.br/json/br/com/b3/tesourodireto/service/api/treasury/getMarket`.
- One request returns every bond under `response.TrsrBdTradgList[].TrsrBd`.
- Match key: `asset.metadata['tesouroName']` when present, else `asset.name`,
  compared to `TrsrBd.nm` after normalization (trim, lowercase, collapse
  whitespace) so an asset named exactly like the bond prices with no extra setup.
- Price = `untrRedVal` (redemption unit value) — what the holder gets today, so
  it is the right figure for current valuation (`untrInvstmtVal` is the buy side).
- No reliable previous close → `previousClose = null` (no day-change for bonds).

### BCB SGS (indices for fixed income)
- `GET https://api.bcb.gov.br/dados/serie/bcdata.sgs.{code}/dados?formato=json&dataInicial=dd/mm/yyyy`.
- Codes: CDI daily = `12`, Selic daily = `11`, IPCA monthly = `433`.

### AwesomeAPI (FX)
- `GET https://economia.awesomeapi.com.br/json/last/USD-BRL` → `USDBRL.bid`.

### API tokens (build-time)
`BRAPI_TOKEN` (brapi) and `FINNHUB_TOKEN` (US equities/ETFs) are baked in at build
time via `--dart-define` — CI passes them from GitHub secrets; local dev uses
`--dart-define-from-file=env.json`. They are **universal** (same for every user),
**not** entered in-app and **not** stored in the database. Caveat: dart-define
values are embedded in the build artifact (readable in the web JS bundle), so only
low-value free-tier keys belong here; true secrecy would need a backend proxy.

## Caching & repository

```dart
abstract class QuoteRepository {
  Future<Either<Failure, List<Quote>>> getCached(List<String> assetIds); // cached-first; folds to [] on error
  Future<Either<Failure, List<Quote>>> refresh(List<Asset> assets);      // fetch + cache
}
```

Rules:
1. **Cached-first**: UI reads cache instantly; refresh runs in background.
2. A registry routes each asset to the first `QuoteDataSource` whose `supports()` is true.
3. Batch by source (one brapi call for all BR tickers; one Finnhub call per US symbol).
4. On fetch failure, keep the previous cached quote and mark it **stale** (`fetchedAt` age).
5. FX and indices cached with their own TTL (FX: minutes; indices: daily).

## Edge cases

- Ticker not found at source → no quote; valuation uses cost basis and flags it.
- Market closed/weekend → price unchanged; `asOf` reflects last session.
- Rate-limit (HTTP 429) → exponential backoff (handled in `sync.md`); serve cache.
- Source schema change → adapter returns `ParseFailure`; other sources unaffected.
