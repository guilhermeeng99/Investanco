# Spec: Allocation (classes, targets, rebalancing)

A user-defined allocation taxonomy on top of the existing holdings, so the user
can set target percentages per class/subclass, **see** how the real (market-valued)
portfolio compares to those targets, and get a **rebalancing** suggestion.

Adapted from `financo`'s investments feature. The key difference: financo stores a
**manual** `amount` per holding; Investanco reuses its **computed market value**
(`ValuationService`) — the user never types amounts. The taxonomy + targets +
rebalancing math are ported; the "current value" comes from real prices.

## Concepts

- **Class**: a user-defined bucket with a target % of the **whole** portfolio
  (e.g. "Ações EUA" → 40%). Has a name, icon, color, target %.
- **Asset = subclass**: each `Asset` is the leaf of a class. The link is set
  **on the asset** — `metadata['allocationClassId']` + `metadata['allocationTargetPercent']`
  — chosen when the user creates/edits the asset (the asset form), **not** by
  creating subclass records. The asset's target % is its share **within its class**.
- A class's current value = Σ market value of the assets assigned to it (across
  institutions).
- **Não alocado (pending)**: market value of holdings whose asset has no
  (resolvable) class assignment.

Classes are flat in the **UI** — no screen creates a child `AssetClass`, and
`computeInvestmentOverview` builds slices only for roots (`where(isRoot)`), so a
non-root class contributes no slice. The `parentId` plumbing nonetheless exists
end-to-end (entity field, `AllocationCubit.createClass(parentId:)`, and a
**cascade delete** that removes a root's children) — reserved for a future
nested-class UI. (Distinct from "Asset = subclass" below, which is per-asset.)

## Entity contract — `AssetClass`

| Field | Type | Invariant |
|-------|------|-----------|
| `id` | String | stable id |
| `name` | String | non-empty (trimmed) |
| `iconKey` | String | key into `allocationIcons` (presentation map) |
| `colorValue` | int | ARGB |
| `targetPercent` | double | `[0, 100]`; root = % of total, subclass = % of parent |
| `parentId` | String? | null = root; non-null = subclass (parent must be a root) |
| `createdAt` | DateTime | |

Getters: `isRoot => parentId == null`, `isSubclass`, `targetFraction => targetPercent/100`.

## Computed entities (not persisted) — `InvestmentOverview`

Produced by the pure `computeInvestmentOverview` from `classes`, `assets` (each
carrying its class + target via metadata), and the valued `holdings`
(`HoldingValuation`). Class totals and targets are in base currency; subclass
rows may also carry a native-currency equivalent for foreign-asset suggestions.

- `InvestmentOverview`: `total`, `allocated`, `pending` (Money), `classes`
  (`List<InvestmentClassSlice>`), `rebalanceActions`, `targetSumPercent`.
  Getters: `hasInvestments` (`total > 0`), `hasPending` (`pending > 0`),
  `targetsBalanced` (`|targetSumPercent − 100| ≤ 0.1`).
- `InvestmentClassSlice`: `id, name, iconKey, colorValue`, `currentValue`,
  `currentPercent` (`[0,1]` of total), `targetPercent`, `targetValue`,
  `deltaValue` (`targetValue − currentValue`; **+ = under → buy, − = over → sell**),
  `subclasses`. `isUnderTarget => deltaValue > 0`.
- `InvestmentSubclassSlice` (one per **asset** in the class): `id` (asset id),
  `name` (ticker), `currentValue`, `percentOfClass` (`[0,1]`), `percentOfTotal`
  (`[0,1]`), `targetPercent` (the asset's target within the class), `suggestedValue`,
  `suggestedDelta` (`suggestedValue − currentValue`, base currency),
  `suggestedDeltaNative` (same delta converted to the asset's native currency
  when the asset is foreign and an FX-derived native/base ratio is available).
- `RebalanceAction`: `classId, className, direction (buy|sell), amount` (Money, >0).

## Algorithm — `computeInvestmentOverview`

Pure, synchronous. `kRebalanceThresholdMinor = 100` (R$1; smaller gaps are noise),
shared from `asset_allocation.dart` by the math and the UI.

1. Market value per asset = Σ `marketValueBase` of its holdings (skip `fxMissing`);
   `total` = Σ all. Group assets under their (existing) class; `allocated` = Σ those.
2. `pending = total − allocated`.
3. Per class: `classTotal = Σ value of its assets`;
   `currentPercent = total==0 ? 0 : classTotal/total`;
   `targetValue = total × targetFraction`; `deltaValue = targetValue − classTotal`.
4. Per asset (subclass slice): `percentOfClass = classTotal==0 ? 0 : v/classTotal`;
   `percentOfTotal`; `suggestedValue = targetValue × assetTarget/100`;
   `suggestedDelta = suggestedValue − v`. For foreign assets, derive
   `suggestedDeltaNative` from the already-valued holding ratio
   `marketValueNative / marketValueBase`; omit it when the asset is in the base
   currency or the ratio cannot be computed.
5. `rebalanceActions`: classes with `|deltaValue| ≥ R$1` → `buy` if delta > 0
   (under), else `sell`; `amount = |deltaValue|`; sorted by amount desc. **Per-class,
   independent** (not netted/paired) — matches financo.
6. `targetSumPercent = Σ classes.targetPercent`. The UI **warns** if `≠ 100 ± 0.1`
   but never blocks.

The "Alocar R$ X não alocado" line is a UI-only prepend when `hasPending`.

## Repository contract — `AssetClassRepository`

```dart
abstract class AssetClassRepository {
  Stream<List<AssetClass>> watchAll();             // ordered by createdAt
  Future<Either<Failure, Unit>> save(AssetClass c);
  Future<Either<Failure, Unit>> delete(String id);
}
```

Firestore-mirrored (`asset_classes` collection), Drift-cached, write-through like
the other repos. Drift table `AssetClasses` (added in schemaVersion 8). The asset→class link
lives in `assets.metadata` (no Assets schema change). Deleting a class leaves its
assets pointing at a missing id → they fall back to **não alocado** automatically.

## Validation rules (`SaveAssetClassUseCase`)

1. `name.trim()` non-empty; `targetPercent ∈ [0,100]` → else `ValidationFailure`.
2. Class target sum: saving a class whose target pushes the total of all classes
   over **100% (+0.01 tol)** is blocked (`ValidationFailure`). Under 100% is allowed
   (UI warns). The asset form requires a class + a target % > 0 for new assets when
   classes exist.

## State machine (`AllocationCubit`)

A `Cubit`. Subscribes to transactions/assets/classes streams; on change it values
the portfolio (cached quotes + FX + indices, like the dashboard) and recomputes the
overview.

```
AllocationLoading
AllocationLoaded(overview, classes, assets, isRefreshing)
AllocationError()
```

On creation the cubit **warm-starts** FX + index series from the durable
`MarketCacheStore`, so a reopened app values foreign holdings + fixed income from
last-known data on the first frame. `refresh({force})` fetches fresh
quotes/FX/indices then recomputes, but skips the network when the held quotes are
within `quoteFreshness`; manual refresh / pull-to-refresh pass `force: true` (see
`quotes.md` rules 6–7). `createClass` / `saveClass` / `deleteClass` manage
classes; the asset→class link is written by the asset form (assets feature) via
`assets.metadata`.

## Edge cases

- No classes → empty state ("create your first class").
- All targets 0 / sum 0 → every class shows as "over by its current value"; UI warns.
- Asset pointing at a deleted class → treated as unassigned (pending).
- Foreign holding with no FX → excluded from total (same as the dashboard).

## UI

- **Investimentos tab** (nav; the app's landing tab — see `records.md`): donut
  (by class) + class list (icon, "X% de Y%",
  value, progress bar current/target, "R$ Z abaixo/acima") + Rebalanceamento card
  (allocate-pending line + per-class buy/sell rows). FAB adds a class.
- **Class detail** (nested under the tab, so the nav shell + a back chip stay):
  hero (value, % of target, target amount, delta) + the class's **assets** (ticker,
  value, "% de %", suggested aporte/reduzir; for foreign assets, the suggestion
  shows BRL plus the native amount in parentheses; tap to edit the asset) + "Adicionar
  ativo" (opens the asset form pre-linked to this class) + edit/delete class.
- **Class form**: name, target %, icon, color.
- **Asset form** (Registros tab → Ativos): adds an allocation-class picker + a target-% field,
  so the link is set at asset creation/edit.

Above/below/on-target colors: under → `warning`, over → `negative`, on → `positive`.
