# Spec: Valuation

Turns holdings + quotes + FX + indices into money figures: current value, P/L,
returns, all consolidated to the base currency (BRL). Pure, deterministic, tested.

## Inputs / output

```dart
class ValuationInput {
  final Holding holding;
  final Asset asset;
  final Quote? quote;                  // null when price unavailable
  final double? fxToBase;              // 1.0 when same currency; null = FX unavailable (foreign holding excluded)
  final FixedIncomeTerms? fixedIncome; // basis + rate + dated cash flows + index series
}

class HoldingValuation {
  final String assetId;
  final String institutionId;
  final AssetKind assetKind;     // for allocation by class
  final double quantity;         // net quantity held
  final Money marketValueBase;   // BRL (native value already × FX)
  final Money marketValueNative; // asset's own currency (USD for an Avenue ETF)
  final Money investedBase;
  final Money unrealizedPL;
  final Money totalPL;           // unrealized + realized + dividends
  final double returnPct;        // guard: 0 when invested == 0
  final Money dayChangeBase;
  final bool priceStale;         // quote missing or old
  final bool fxMissing;          // foreign holding with no FX → excluded from totals
}
```

## Rules (mirror overview §6)

1. **Market value (native)** = `quantity * quote.unitPrice`.
2. **Fixed income** (no market quote): valued from dated **cash flows** — a buy is
   a deposit (aplicação, positive), a sell a redemption (resgate, negative). By
   linearity of daily accrual, `currentValue = Σ amount * accrualFactor(flow.date)`
   and `invested = Σ amount` (net contributions); both come from the flows, not
   the share/average-cost model — so partial redemptions are handled natively and
   a sell's "realized P/L" is never double counted (`totalPL = unrealizedPL`). A
   single deposit reproduces the old `principal * factor`. `accrualFactor` follows
   `basis`; `ratePercent` meaning: CDI/Selic → percent **of** the index (110 =
   110% of CDI); prefixed → annual rate; IPCA+ → annual spread.
   - CDI: `∏(1 + (dailyCdi_d/100) * (ratePercent/100))` over each series day ≥ the flow date.
   - Selic: same shape with the Selic daily series.
   - Prefixed: `(1 + ratePercent/100)^(businessDays/252)`.
   - IPCA+: `(∏(1 + ipca_m/100)) * (1 + ratePercent/100)^(businessDays/252)`.
   `businessDays` counts weekdays since the flow date (bank holidays ignored — the
   BCB series already excludes them for index bonds; only prefixed/IPCA+ are
   slightly affected). Falls back to cost + `priceStale` only when `fixedIncome`
   is absent or has no cash flows.
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
  final Map<Currency, Money> byCurrency;      // native value per currency
  final List<HoldingValuation> holdings;
}
```

`PortfolioValuation.fromHoldings(holdings, base)` is the single aggregation point
(FX-missing holdings excluded from totals, kept in `holdings`); `forInstitution(id?)`
re-runs it over the matching subset for the dashboard's institution filter.
`byCurrency` sums each holding's `marketValueNative` by its own currency, letting the
UI show the dollar subtotal of dollar holdings.

## Edge cases

- Missing quote → `marketValue` falls back to `investedBase`, `priceStale = true`,
  `unrealizedPL = 0` (don't fabricate gains).
- Missing FX for a foreign holding → exclude from `totalValueBase`, surface a warning.
- Closed holding (qty 0) → contributes realized P/L + dividends only.
- Negative quantity (data error) → clamp to 0 and flag (should be prevented upstream).

## Tests (required)

Weighted average across multiple buys; sell realized P/L; CDI accrual vs a known
fixture; USD holding consolidation; div-by-zero guard; stale-quote fallback.
