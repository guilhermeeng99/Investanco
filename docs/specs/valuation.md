# Spec: Valuation

Turns holdings + quotes + FX + indices into money figures: current value, P/L,
returns, all consolidated to the base currency (BRL). Pure, deterministic, tested.

## Inputs / output

```dart
class ValuationInput {
  final Holding holding;
  final Asset asset;
  final Quote? quote;          // null when price unavailable
  final double? fxToBase;      // null when same currency
  final List<IndexPoint>? index; // for fixed income
}

class HoldingValuation {
  final Money marketValueNative;
  final Money marketValueBase;   // BRL
  final Money investedBase;
  final Money unrealizedPL;
  final Money totalPL;           // unrealized + realized + dividends
  final double returnPct;        // guard: 0 when invested == 0
  final Money dayChangeBase;
  final bool priceStale;         // quote missing or old
}
```

## Rules (mirror overview §6)

1. **Market value (native)** = `quantity * quote.unitPrice`.
2. **Fixed income** (no market quote): `currentValue = principal * accrualFactor`,
   where `accrualFactor` is built from the index series and the contracted rate:
   - CDI: `∏(1 + dailyCdi_d * ratePercent)` over business days since purchase.
   - Selic: same shape with Selic daily.
   - Prefixed: `(1 + annualRate)^(daysHeld/252)`.
   - IPCA+: `(1 + ipcaAccum) * (1 + spread)^(daysHeld/252)`.
3. **Base conversion**: `valueBase = marketValueNative * fxToBase` (fxToBase = 1 when
   currency == base).
4. **Unrealized P/L** = `marketValueBase - investedBase`.
5. **Return %** = `unrealizedPL / investedBase`; return `0.0` if `investedBase == 0`.
6. **Total P/L** = `unrealizedPL + realizedPL(base) + dividends(base)`.
7. **Day change** = `(unitPrice - previousClose) * quantity * fxToBase`; `0` if
   `previousClose` is null.
8. **Stale flag** = quote null OR `now - quote.fetchedAt > staleThreshold`.

## Portfolio aggregation

```dart
class PortfolioValuation {
  final Money totalValueBase;
  final Money totalInvestedBase;
  final Money totalUnrealizedPL;
  final Money totalDayChangeBase;
  final double totalReturnPct;
  final Map<AssetKind, Money> byClass;        // allocation
  final Map<String, Money> byInstitution;     // allocation
  final List<HoldingValuation> holdings;
}
```

## Edge cases

- Missing quote → `marketValue` falls back to `investedBase`, `priceStale = true`,
  `unrealizedPL = 0` (don't fabricate gains).
- Missing FX for a foreign holding → exclude from `totalValueBase`, surface a warning.
- Closed holding (qty 0) → contributes realized P/L + dividends only.
- Negative quantity (data error) → clamp to 0 and flag (should be prevented upstream).

## Tests (required)

Weighted average across multiple buys; sell realized P/L; CDI accrual vs a known
fixture; USD holding consolidation; div-by-zero guard; stale-quote fallback.
