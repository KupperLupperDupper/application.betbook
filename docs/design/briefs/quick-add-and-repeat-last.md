# Claude Design brief — BetBook: quick-add & repeat-last logging

Paste everything below into Claude Design. It **extends the existing BetBook
design system** — do not restyle the app. Reference the latest handoff
`docs/design/from-claude-design-v3/DESIGN_HANDOFF.md` and `.../MOTION_HANDOFF.md`
(tokens, ColorSchemes, `MoneyColors`, Manrope, the card deck, the FAB) and
`.../mockups/`.

---

## Context

BetBook is a calm, offline ledger for betting deposits/withdrawals — **"a
ledger, not a casino."** Logging a transaction today is a **full-screen route**:
the amount is entered on a **custom on-screen keypad** (the OS keyboard is never
summoned for it), with a **deposit/withdrawal** type toggle, a **site** picker,
a **date**, and an optional **note**. It's opened from the **Dashboard FAB** (a
compact "+") and the Sites "Add" flow.

A frequent user logs many similar transactions (same site, similar amounts),
so the full screen is heavier than it needs to be for the common case.

## Goal

Make repeat logging **fast** without losing the deliberate, calm feel:
1. **Quick-add** — a lightweight path to log a transaction in a few taps
   (amount + site + type), without the full-screen route when the user doesn't
   need date/note.
2. **Repeat-last** — a one-gesture way to re-log the previous transaction (same
   site/type/amount, dated now), editable before commit.

These are **accelerators layered on top of** the existing full editor — they
must never replace it or hide the ability to set date/note/site precisely.

## Open design decisions — please decide and justify briefly

1. **Quick-add surface**: a bottom sheet from the FAB, an expanded FAB menu, or
   inline on the Dashboard? Recommend one and say why it fits the deck/FAB
   layout (FAB is centred in its own band above the suit indicator).
2. **Repeat-last trigger**: long-press the FAB, a "repeat" action on the most
   recent transaction row, or a chip on the quick-add sheet? Pick the most
   discoverable that doesn't clutter.
3. **Amount presets**: should quick-add offer amount chips (e.g. recent/common
   amounts per site, or round numbers)? If yes, how are they derived and how
   many, without becoming a "suggested bet" nudge (which would cross into
   casino territory).
4. **Default site**: how quick-add picks the initial site (last used? most
   active? the site whose detail you're on?). Define the rule.

## Scope — specify each, with light + dark values and reduced-motion fallbacks

1. **Quick-add sheet/menu.** Full layout and states: amount entry (reuse the
   existing keypad styling — decide if the keypad appears in the sheet or the
   sheet is chip/stepper-based), the type toggle, the site selector (compact,
   using the mini playing-card avatar), the confirm action, and an **"More /
   full editor"** escape hatch that carries the entered values into the
   full-screen route. Show validation (no amount / no site) and the success
   confirmation (fits the existing SnackBar pattern).
2. **Repeat-last.** The trigger's affordance and discoverability, a **confirm
   step that shows exactly what will be logged** (site · type · amount · "now"),
   and how the user tweaks it before committing (jump into quick-add or the full
   editor pre-filled). Define the empty state (nothing logged yet → trigger is
   absent or disabled, not a dead button).
3. **Entry animation** for the sheet/menu consistent with the deck's calm motion
   (no bounce; a soft settle), plus the FAB's role during it.
4. **Where repeat-last lives on the Dashboard** relative to the recent-activity
   list and the hero figure, if it has a persistent affordance there.

## Non-negotiables

- **Calm over casino.** Speed, not urgency. **No** "quick bet again!", streak
  counters, hot-amount nudges, celebratory motion, or anything that encourages
  volume. Amount presets (if any) must read as neutral recall, never suggestion.
- The **full editor stays the source of truth** — quick-add is a shortcut into
  the same data; date/note remain reachable.
- Reuse existing tokens (ColorSchemes, `MoneyColors`, radii, spacing, Manrope,
  the keypad, the mini-card avatar); any new token in hex for **both** themes.
- Profit/loss colour only on net figures, always with sign + trend icon;
  individual deposit/withdraw amounts stay `onSurface`.
- **Reduced motion**: sheet/menu appears without animation when
  `MediaQuery.disableAnimations` is set.
- **Localised** English + Danish; Danish runs longer — controls must not clip.
- Portrait-only, 60 fps mid-range Android; one-handed reach matters (the sheet's
  primary controls should sit in the lower half).

## Deliverables

1. **Mockups** (light + dark) of: the quick-add surface (empty + filled +
   validation states), the repeat-last confirm step, and the FAB/trigger states.
2. A **design-handoff markdown** (same structure as `DESIGN_HANDOFF.md`):
   component specs, any new tokens (hex, both themes), the quick-add and
   repeat-last interaction flows (including the escape hatch into the full
   editor and the default-site/preset rules), states, and reduced-motion +
   localisation notes. Make it self-contained — this is what I implement from.
