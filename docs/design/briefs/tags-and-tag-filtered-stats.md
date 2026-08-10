# Claude Design brief — BetBook: tags + tag-filtered stats

Paste everything below into Claude Design. It **extends the existing BetBook
design system** — do not restyle the app. Reference the latest handoff
`docs/design/from-claude-design-v3/DESIGN_HANDOFF.md` and
`.../MOTION_HANDOFF.md` (tokens, ColorSchemes, `MoneyColors`, Manrope
typography, the card-deck navigation, the mini playing-card avatar), and the
mockups in `.../mockups/betbook-mockups.html`.

---

## Context

BetBook is a calm, offline ledger for betting deposits/withdrawals — **"a
ledger, not a casino."** Data model today: **Sites** (name, currency, colour)
each own **Transactions** (type = deposit/withdrawal, amount in minor units,
date, optional note). Money is shown in a base currency; profit/loss colour
(teal-green / orange-red from `MoneyColors`) appears **only on net figures**,
always paired with a +/− sign and a trend icon.

The four sections are swipeable cards: Dashboard ♠ · Sites ♥ · **Stats ♦** ·
Settings ♣. The **Stats** card currently has: a range selector (chips), a hero
net figure, a cumulative line chart, a per-site breakdown (horizontal bars), a
best/worst pair of cards, and a monthly bar chart.

## Goal

Let the user attach **tags** to transactions (e.g. `football`, `poker`,
`bonus`, `live`, `accumulator`) and then **filter Stats by tag** to see P/L for
just that activity. Tags are a lightweight, user-defined taxonomy — not a
second currency, not categories with rules.

Design **both**:
1. **Tagging** — creating/assigning/removing tags on a transaction, and managing
   the tag set.
2. **Tag-filtered Stats** — a filter affordance on the Stats card and how every
   figure/chart there responds.

## Open design decisions — please decide and justify briefly

1. **What can be tagged?** Recommend transaction-level tags (multiple per
   transaction). Say whether a site can carry a default tag that new
   transactions inherit.
2. **How many tags per transaction** feel right before the row gets noisy? Give
   a display rule for the transaction row and site-detail list (e.g. show N,
   then "+2").
3. **Tag colour**: do tags get their own colour, or stay neutral chips (so they
   never compete with `MoneyColors`)? If coloured, define a small palette in hex
   for light + dark that is visually distinct from profit/loss/neutral.
4. **Filter model on Stats**: single-tag filter or multi-select? AND vs OR for
   multiple? Recommend the simplest that's still useful.

## Scope — specify each, with light + dark values and reduced-motion fallbacks

1. **Tag chip** — the core component. Define resting/selected/disabled states,
   size, radius, typography, max width + truncation, and the "add tag" and
   "remove" affordances. It must read as calm metadata, never as a reward badge.
2. **Assigning tags on add/edit transaction.** The add-transaction screen uses a
   custom keypad for the amount plus a type toggle, site picker, date, and note.
   Show where tags go, how the user picks existing tags vs. creates a new one
   (inline autocomplete/typeahead), and the empty state (no tags yet).
3. **Tag management.** Where the master list of tags lives (likely a Settings ›
   Data entry or a screen reached from the tag picker): rename, delete
   (with the consequence — deleting a tag just unassigns it, transactions
   remain), and merge if you think it's warranted. Deletion must fit the app's
   existing **Undo SnackBar** pattern.
4. **Tags in the transaction row** (Dashboard recent list + site-detail list):
   how tags appear without breaking the current row rhythm (amount stays
   `onSurface`; net colour rules unchanged).
5. **Tag filter on the Stats card.** The filter control (where it sits relative
   to the existing range chips), its selected state, and a clear/"All" reset.
   Define exactly how each Stats element re-reads under a filter: hero net, line
   chart, per-site breakdown, best/worst, monthly bars. Include the **empty
   state** (a tag with no transactions in range) and whether the filter persists
   across app launches.
6. **Discoverability**: how a first-time user learns tags exist without an
   intrusive tutorial.

## Non-negotiables

- **Calm over casino.** Tags are organisational, not gamified — no streaks,
  levels, achievements, or celebratory motion.
- Reuse existing tokens (ColorSchemes, `MoneyColors`, radii, spacing, Manrope).
  Any new token defined in hex for **both** themes.
- Profit/loss colour only on net figures, always with sign + trend icon.
- **Reduced motion**: every transition (filter apply, chip select, chart
  re-draw) has an instant, non-animated fallback.
- **Localised**: all copy ships in English + Danish; never hardcode strings.
  Danish tends longer — chips and controls must not clip (we have had Danish
  wrapping bugs before).
- 60 fps mid-range Android; transform/opacity over layout.
- Icon tree-shaking: avoid storing arbitrary `IconData`; if tags need a glyph,
  prefer text/first-letter or a small fixed set.

## Deliverables

1. **Mockups** (light + dark) of: transaction row with tags, add/edit
   transaction with the tag picker, tag management screen, and the Stats card
   under an active tag filter (plus its empty state).
2. A **design-handoff markdown** (same structure as the existing
   `DESIGN_HANDOFF.md`): the tag-chip component spec, all new tokens (hex, both
   themes), the tag-picker interaction, the Stats-filter behaviour per element,
   states, and reduced-motion + localisation notes. This is what I implement
   from — make it self-contained.
