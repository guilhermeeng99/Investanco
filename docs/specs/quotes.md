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
| `source` | `QuoteSource` | brapi / yahoo / tesouro / bcb / manual |

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

### brapi (BR equities, FII, ETF, BDR, crypto)
- `GET https://brapi.dev/api/quote/{TICKERS}?token={TOKEN}` (comma-separated, batched).
- Map: `regularMarketPrice → unitPrice`, `regularMarketPreviousClose → previousClose`.
- Token from `--dart-define=BRAPI_TOKEN=...` (free tier). Empty token → limited tickers.

### Yahoo Finance (US equities/ETF — Avenue)
- `GET https://query1.finance.yahoo.com/v8/finance/chart/{SYMBOL}`.
- Map: `chart.result[0].meta.regularMarketPrice` / `previousClose`. Currency `usd`.
- No key. Treat as best-effort; on failure, fall back to last cached quote.

### Tesouro Direto (bonds)
- `GET https://www.tesourodireto.com.br/json/br/com/b3/tesourodireto/service/api/treasury/getMarket`.
- Match `asset.metadata['tesouroName']` to `TrsrBd.nm`; price = `untrRedVal` (sell)
  or `untrInvstmtVal` (buy); use redemption value for current valuation.

### BCB SGS (indices for fixed income)
- `GET https://api.bcb.gov.br/dados/serie/bcdata.sgs.{code}/dados?formato=json&dataInicial=dd/mm/yyyy`.
- Codes: CDI daily = `12`, Selic daily = `11`, IPCA monthly = `433`.

### AwesomeAPI (FX)
- `GET https://economia.awesomeapi.com.br/json/last/USD-BRL` → `USDBRL.bid`.

## Caching & repository

```dart
abstract class QuoteRepository {
  Future<Either<Failure, List<Quote>>> getCached(List<String> assetIds);
  Future<Either<Failure, List<Quote>>> refresh(List<Asset> assets); // fetch + cache
}
```

Rules:
1. **Cached-first**: UI reads cache instantly; refresh runs in background.
2. A registry routes each asset to the first `QuoteDataSource` whose `supports()` is true.
3. Batch by source (one brapi call for all BR tickers; one Yahoo call per US symbol).
4. On fetch failure, keep the previous cached quote and mark it **stale** (`fetchedAt` age).
5. FX and indices cached with their own TTL (FX: minutes; indices: daily).

## Edge cases

- Ticker not found at source → no quote; valuation uses cost basis and flags it.
- Market closed/weekend → price unchanged; `asOf` reflects last session.
- Rate-limit (HTTP 429) → exponential backoff (handled in `sync.md`); serve cache.
- Source schema change → adapter returns `ParseFailure`; other sources unaffected.
