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

Classes are flat (`AssetClass`, all roots). `parentId` exists on the entity but is
currently unused by the UI (reserved).

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
(`HoldingValuation`). All money in base currency.

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
  `suggestedDelta` (`suggestedValue − currentValue`).
- `RebalanceAction`: `classId, className, direction (buy|sell), amount` (Money, >0).

## Algorithm — `computeInvestmentOverview`

Pure, synchronous. `_minRebalanceMinor = 100` (R$1; smaller gaps are noise).

1. Market value per asset = Σ `marketValueBase` of its holdings (skip `fxMissing`);
   `total` = Σ all. Group assets under their (existing) class; `allocated` = Σ those.
2. `pending = total − allocated`.
3. Per class: `classTotal = Σ value of its assets`;
   `currentPercent = total==0 ? 0 : classTotal/total`;
   `targetValue = total × targetFraction`; `deltaValue = targetValue − classTotal`.
4. Per asset (subclass slice): `percentOfClass = classTotal==0 ? 0 : v/classTotal`;
   `percentOfTotal`; `suggestedValue = targetValue × assetTarget/100`;
   `suggestedDelta = suggestedValue − v`.
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
the other repos. Drift table `AssetClasses` (schemaVersion 8). The asset→class link
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

`refresh()` fetches fresh quotes/FX/indices then recomputes. `createClass` /
`saveClass` / `deleteClass` manage classes; the asset→class link is written by the
asset form (assets feature) via `assets.metadata`.

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
  value, "% de %", suggested aporte/reduzir; tap to edit the asset) + "Adicionar
  ativo" (opens the asset form pre-linked to this class) + edit/delete class.
- **Class form**: name, target %, icon, color.
- **Asset form** (Registros tab → Ativos): adds an allocation-class picker + a target-% field,
  so the link is set at asset creation/edit.

Above/below/on-target colors: under → `warning`, over → `negative`, on → `positive`.
