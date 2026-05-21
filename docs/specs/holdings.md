# Spec: Holdings

A **derived** view: the net position of one asset at one institution — quantity and
weighted average cost — computed from its transactions. Not stored as a primary
record; recomputed (and may be cached) from transactions.

## Derived contract

| Field | Type | Derivation |
|-------|------|------------|
| `assetId` | String | group key |
| `institutionId` | String | group key |
| `quantity` | Decimal | Σ buys − Σ sells |
| `avgCost` | Money (native) | weighted average incl. fees (overview §6.1) |
| `investedCost` | Money | computed getter: `quantity * avgCost` |
| `realizedPL` | Money | Σ realized gains/losses from sells |
| `dividends` | Money | Σ dividend amounts |

`Holding` is a value object (Equatable, no id).

## Business rules

1. Holdings with `quantity == 0` are **closed** — excluded from current allocation
   but retained for realized P/L history.
2. Average cost uses the **weighted** method (overview §6.1). FIFO is out of scope v1.
3. A holding is keyed by `(assetId, institutionId)`; the same asset at two
   institutions is two holdings (aggregated in the dashboard by asset when needed).
4. Recomputation is pure and deterministic given the ordered transaction list.

## Service contract

```dart
abstract class HoldingCalculator {
  /// Pure: derives holdings from a transaction list, ordered by date.
  List<Holding> derive(List<AssetTransaction> transactions);
}
```

## Edge cases

- Sell to exactly zero → holding closed, `avgCost` retained for the realized record.
- Dividends on a closed holding → counted in `dividends`, holding stays closed.
- Out-of-order transaction dates → calculator sorts by `date` then `createdAt`.
- Fractional quantities (US/crypto) → supported via Decimal with fixed scale.
