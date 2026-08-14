# Claude Design brief — BetBook: bottom nav bar with a centered add button + section dots

Paste into Claude Design. This **replaces the v5 bottom nav pill and the
corner FAB** with a single bottom bar. It builds on the existing system — read
`docs/design/from-claude-design-v5/FULLBLEED_HANDOFF.md` (§4 the nav pill this
supersedes, §5 swipe affordance), `.../DESIGN_HANDOFF.md`, `.../MOTION_HANDOFF.md`,
and `CLAUDE.md` (**calm over casino, no new motion vocabulary, no shadows** —
one light-theme FAB shadow is the only shadow in the app). `mockups/`.

---

## Context

BetBook's home is a full-bleed deck of four sections the user swipes between —
Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣ — each identified by a suit. v5
gave the bottom a small **nav pill** of the four suit glyphs (active one in a
`primaryContainer` capsule) and a separate **circular FAB** bottom-right whose
action depends on the section (add transaction on Dashboard, add site on Sites;
Stats and Settings have no add action, so the FAB is simply absent).

The owner wants to combine these into **one better bottom bar**:

- a **centered circular add (+) button**,
- **page-indicator dots** on each side of it showing which of the four sections
  is active,
- and when the current section has **no** add action, the add button should
  **smoothly animate off-screen**, returning (animated) when a section that
  needs it is shown.

## Goal

Design one anchored bottom bar carrying both **navigation feedback** (which
section) and the **primary add action**, with the add button appearing only on
sections that have one. It must stay calm and keep the deck's suit identity.

## Open decisions — please resolve and justify

1. **Dots vs suits.** The four sections currently carry suit identity. Do the
   side indicators become **plain dots** (4 dots, active one filled/primary) or
   **the four suit glyphs as the dots** (preserving ♠♥♦♣ identity, active one
   emphasised)? Recommend one — leaning toward keeping the suit identity unless
   plain dots are clearly calmer/cleaner. Whatever you choose, there are **four**
   sections and one centre button.
2. **Layout around the centre.** With a centred button and four sections, how do
   the indicators sit — two each side (`• •  (+)  • •`), i.e. Dashboard/Sites
   left, Stats/Settings right — and how does the active indicator read (fill,
   size, colour, a capsule)? Specify spacing/sizes.
3. **Are the dots tappable?** Swipe stays the primary section switch. Should
   tapping a dot/suit also navigate (as the v5 pill did), or is the bar
   indicator-only? Recommend, with a11y in mind.
4. **Add-button show/hide.** Exact animation when moving between a section with
   an add action (Dashboard, Sites) and one without (Stats, Settings): scale +
   fade, slide down, or morph; duration/curve; and what the **dots do** when the
   button leaves (re-centre / re-space to fill the gap, or hold position).
   Reduced-motion fallback (instant show/hide, no reflow jump).

## Scope — specify each, light + dark, with reduced-motion fallbacks

1. **The bar container.** Anchored bottom, safe-area aware, over full-bleed
   scrolling content — so it needs its own **opaque** treatment (no scrim/blur/
   gradient, per the rules), like the v5 pill's `surfaceContainerHigh` + hairline.
   Height, radius, horizontal inset, elevation (tonal only).
2. **The centre add button.** Circular, `primaryContainer`/`onPrimaryContainer`
   + the one allowed light shadow, `add` glyph. Size and how it sits relative to
   the bar (inset, or raised/notched above it — but keep it calm, no big
   floating orb). Its action is always "+": Dashboard → add transaction, Sites →
   add site. Pressed/disabled states.
3. **The section indicators** (per decisions 1–2): resting vs active, colour,
   size, the active transition as the page offset changes (cross-fade with
   swipe, like the pill today).
4. **The add-button transition** (decision 4) as its own timed spec, plus how it
   composes with the deal-in on first launch (the bar + button should still fade
   in with the deck, not pop).
5. **A11y & semantics.** The add button announces as a button with its action;
   indicators announce section + selected state (and as buttons if tappable).
   Tap targets ≥ 48 dp even if the dots are visually small.
6. **What it replaces.** State explicitly that this supersedes v5 §4 (nav pill)
   and the corner FAB, and that the deck, swipe transforms, drag seam, first-run
   nudge, deal-in, settle, count-up, shuffle and skeletons are otherwise
   unchanged. Confirm section scroll padding still clears the new bar (v5 used
   `bottom: 140`).

## Non-negotiables

- **Calm over casino.** No new motion vocabulary, no shadow beyond the single
  FAB shadow, no bounce/overshoot, no colour on the dots beyond the theme's
  primary/neutral. The centred add button must not read as a slot-machine button.
- **Reduced motion:** the add-button show/hide and any indicator motion have an
  instant fallback; the bar's identity survives static.
- Reuse existing tokens (`MoneyColors`, `primaryContainer`, `surfaceContainerHigh`,
  `DeckSurface.hairline`, Manrope, radii). Any new token in hex/dp for **both**
  themes.
- **Localised** (en/da); no clipping. Portrait, 60 fps mid-range Android;
  `transform`/`opacity` only.

## Deliverables

1. **Mockups** (light + dark) of the bar on a section **with** the add button
   (Dashboard) and **without** it (Stats), plus a mid-transition frame of the
   button animating out and the dots re-settling.
2. A **design-handoff markdown** (same structure as the v5 handoffs): the bar +
   button + indicator specs with exact sizes/tokens, the resolved decisions 1–4,
   the add-button show/hide timing, a11y, and reduced-motion notes.
   Self-contained — this is what I implement from.
