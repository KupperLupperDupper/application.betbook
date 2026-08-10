# Claude Design brief — BetBook "card-deck personality" polish

Paste everything below into Claude Design. It builds on the **existing BetBook
design system** — do not restyle the app; extend it. Reference:
`docs/design/from-claude-design/DESIGN_HANDOFF.md` (tokens, ColorSchemes,
`MoneyColors`, typography, and §6 the card-deck navigation) and
`docs/design/from-claude-design/mockups/betbook-mockups.html`.

---

## Context

BetBook is a calm, offline ledger for tracking betting deposits/withdrawals —
**"a ledger, not a casino."** The signature interaction is the **card deck**:
the four top-level sections (Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣) are
full-bleed cards the user swipes between, with a bottom ♠♥♦♣ indicator. The app
already has: hand-tuned M3 ColorSchemes, Slate-Blue `#3B5F9E` accent, Manrope
type, `MoneyColors` (profit teal-green / loss orange-red), quiet corner pips,
peeking neighbour cards, and a soft spring settle.

## Goal

Make the **printed-playing-card personality** come through a little more —
mostly via **motion** plus a few small component touches — **without ever
becoming casino-flashy.** Quiet, tactile, "beautifully printed deck," never
slot-machine.

## Non-negotiables (carry over from the existing system)

- **Calm over casino.** No confetti, coins, jackpots, streaks, rewards, sounds,
  or celebratory/sympathetic animation of any kind. Gains and losses are stated,
  not dramatised.
- **Reduced motion:** every animation below MUST have an instant, non-animated
  fallback when `MediaQuery.disableAnimations` is true (deck transitions become
  instant page changes; count-up is skipped; loaders become a static state).
- **Performance:** 60 fps on mid-range Android; prefer transform/opacity over
  layout; no heavy shadows (tonal depth only, per the system).
- **Reuse tokens.** Use the existing ColorSchemes, `MoneyColors`, radii,
  spacing, and Manrope. If you introduce a new token (e.g. a card-back tint or a
  paper texture), define it explicitly in hex for **both light and dark**.
- Profit/loss colour rules unchanged: colour only on net figures, always with
  sign + directional icon.

## Scope — specify each of these

For every animation give: **trigger, duration, curve, choreography, and the
reduced-motion fallback.** For every visual give light + dark values.

1. **Deck section transition ("deal / flip").** Refine the swipe/tap transition
   between the four section cards so it reads as dealing through a deck. Build on
   the existing spec (viewportFraction 0.92; active→neighbour scale 1.0→0.94;
   opacity 1.0→0.86; 0.15× content parallax; `SpringDescription(mass 1,
   stiffness 220, damping 26)`; `HapticFeedback.selectionClick()` on settle).
   Also define a **"deal-in" on first app open** — the cards fan/settle into
   place once, briefly. Keep it a single soft motion, no bounce.

2. **Pull-to-refresh "shuffle."** A custom refresh indicator on the Dashboard /
   Sites lists that reads as a quick riffle of the four suits (not a spinner).
   Specify frames/timing and the resting state. NOTE for the dev: data is local
   and reactive, so this is a **flourish**; tie the actual refresh to the manual
   FX-rate update (or make it purely decorative). Include the reduced-motion
   static fallback.

3. **Mini playing-card site avatars.** Evolve today's 40 dp colour rounded-square
   + first-initial into a small **playing-card chip**: the site's colour, the
   initial as the "rank," and a tiny suit pip in a corner (assign a suit per site
   deterministically). Specify size, corner radius, pip size/placement, contrast,
   and how it scales between list rows (40 dp) and the site-detail hero. Must stay
   instantly legible and never cluttered.

4. **Suit-themed loading + skeletons.** Replace the plain
   `CircularProgressIndicator` with an on-brand loader (e.g. the four suits
   dealing/pulsing) and define shimmer **skeleton** layouts for the Dashboard,
   Sites, and Stats cards while data resolves. Specify motion, timing, and the
   skeleton block layout per screen. Reduced-motion → static skeleton, no shimmer.

5. **Hero P/L count-up + zero-crossing.** Reaffirm and fully spec §3.13: the
   overall P/L figure counts up (≈400 ms `easeOutCubic`, once per screen entry,
   only when the value changed); at a zero crossing the colour + sign cross-fade
   (≈250 ms) and the trend arrow rotates through the flat state — no flash, no
   bounce. Give exact, implementable values.

6. **Optional quiet card texture.** Consider whether a *very* subtle paper/linen
   tint or hairline on the deck cards strengthens the "printed card" feel while
   staying calm. If yes, define it precisely (light + dark) and where it applies;
   if it risks noise, say so and skip it.

## Accessibility

- Reduced-motion fallback for every item above (list them explicitly).
- Maintain WCAG AA contrast on the mini-card avatars, suit pips, and loaders.
- Motion must never be the only carrier of meaning.

## Deliverables (please return all)

1. A **motion & interaction spec** — one entry per animation with trigger,
   duration, curve, choreography, and reduced-motion fallback.
2. **Visual specs** for the new/updated components (mini-card avatar, suit
   loader, skeletons, refresh shuffle) with tokens, in **light + dark**.
3. **Mockups / frames** where a picture helps (the deal-in, the mini-card
   avatar, the shuffle, the skeletons).
4. A structured **`DESIGN_HANDOFF.md`-style Markdown** a Flutter developer can
   implement from directly (this is a required standalone artifact, not prose).

Keep it consistent with the existing handoff so it drops into the current theme
and `AppDeck`/`MoneyColors`/Manrope system without restyling anything else.
