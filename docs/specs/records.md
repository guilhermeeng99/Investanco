# Spec: Records (unified Assets + Transactions tab)

The third primary tab. Merges the former **Assets** and **Transactions** tabs into
one swipeable surface so the two things the user manually maintains live together,
freeing the bottom bar for the two *read* tabs (Investimentos, Carteira).

Presentation-only by design: it owns no entity, repository or use case — it
composes the existing Assets and Transactions presentation. The business rules,
contracts and state machines stay in `assets.md` and `transactions.md`.

## Tab order *(set here for the whole app)*

The shell hosts three primary tabs + a profile destination. Cold start lands on
**Investimentos** (the landing tab; see `startup.md`):

| Index | Tab | Route | Source |
|-------|-----|-------|--------|
| 0 | Investimentos | `/allocation` | `allocation.md` |
| 1 | Carteira | `/dashboard` | `dashboard.md` |
| 2 | Registros | `/records` | this spec |
| 3 | Perfil (rail tile / bar user icon) | `/profile` | `profile.md` |

## Structure

`RecordsPage` (a `StatefulWidget`) provides both feature cubits via
`MultiBlocProvider` (so the body **and** the FAB share each scope), then renders a
single `Scaffold`:

- `InvestancoAppBar(title: t.nav.records)` — one bar for both sub-views.
- A segmented `InvestancoPillToggle<RecordsTab>` (Ativos / Lançamentos) above a
  `PageView`; tap animates the page, swipe drives the toggle (kept in sync via
  `onPageChanged`).
- Body pages are the embeddable `AssetsView` / `TransactionsView` (the former page
  bodies, minus their own Scaffold).
- `floatingActionButton` swaps to the active sub-view's stack (`AssetsFab` /
  `TransactionsFab`) — only one is mounted at a time, so their `ImportAddFab`
  hero prefixes never clash.

## State machine

Local widget state only (no cubit): `RecordsTab _current` ∈ {`assets`,
`transactions`}, mirrored by a `PageController`.

- Tap toggle → set `_current` (instant highlight + FAB swap) then `animateToPage`.
- Swipe → `onPageChanged` sets `_current`.

## Deep link

`recordsTabFromQuery(String?)` maps the `tab` query param to the initial sub-view:
`'transactions'` → transactions, anything else (incl. null) → assets. The router
reads `state.uri.queryParameters['tab']`; the dashboard onboarding CTAs use it
(`/records?tab=assets`, `/records?tab=transactions`) to land on the right step.

## Edge cases

- No `tab` / unknown value → assets sub-view (the default).
- Both cubits load on first entry to the tab (instant swipe), and persist while the
  shell branch stays alive — same lifetime the two separate branches had before.
