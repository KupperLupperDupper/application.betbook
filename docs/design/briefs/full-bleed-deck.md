# Claude Design brief — BetBook: full-bleed deck (fix the cramped layout)

Paste into Claude Design. This is a **layout/motion tuning revision** of the
existing card-deck navigation, not a new feature and not a re-theme. Read the
v4 handoff first: `docs/design/from-claude-design-v4/DESIGN_HANDOFF.md` (§6 the
card deck, §2.9 the tablet NavigationRail degrade), `.../MOTION_HANDOFF.md`
(§1 deck transitions, deal-in, settle), and `.../mockups/`.

---

## Problem (from user testing)

The four sections (Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣) are a
horizontal deck of playing cards the user swipes between. Users report the card
page view **"makes the layout feel small and cramped."**

The cause is **compounded horizontal inset**, not the metaphor. On a ~393 dp
screen the deck spends, before any content is drawn:

- **~31 dp** to `viewportFraction 0.92` (the peeking neighbour cards, ~15.7 dp
  each side),
- **12 dp** to `PlayingCard`'s own `left/right: 6` padding,
- plus each section's inner header + body gutter (~20 dp/side, legitimate
  reading margin).

So the active card fill is only ~89% of the screen and the real content column
~79% — that ~21% white margin is the "cramped" feeling. (The `PlayingCard` doc
comment already *claims* full-bleed; the code contradicts it.)

## Goal

Make the **active card effectively full-screen (edge-to-edge content)** while
**keeping the entire deck personality and all its animations.** Both engineering
analyses independently recommend this over any re-theme, because:

- The swipe transforms (scale/opacity/tilt/stack-drop) are already **drag-scoped
  and self-zero at rest** — at `viewportFraction 1.0` the outgoing card still
  lifts/tilts as the finger drags, then parks flush. Nothing about the motion
  needs the permanent peek sliver.
- Deal-in, settle-emphasis, count-up wave, pull-to-refresh shuffle, and
  skeletons all live in decoupled widgets invoked *inside* each section — they
  carry over untouched.

**Do NOT redesign the metaphor.** The swipe-between-playing-cards deck is the
owner's deliberate signature identity. This brief is about reclaiming the
wasted inset, not trading away deck-ness.

## Recommended direction (please refine the exact values)

Full-bleed the active card and cover the lost peek with motion, not margin:

| Knob | Current | Proposed |
|---|---|---|
| `viewportFraction` | `0.92` | **`1.0`** (or `~0.97` — see decision 1) |
| `PlayingCard` outer padding | `top 6 / bottom 12 / left 6 / right 6` | **`0`** on the active card |
| Card corner radius | `28` all corners (border + clip) | **`28` top corners only** (bottom runs off-screen) |
| Hairline border / top edge-lift | inset 6 dp | **flush to the screen edge**, same colour/opacity |
| At-rest peek | ~15.7 dp each side | **0 at rest**; optional 6–8 dp **drag-only seam** that opens while swiping and closes to 0 at rest |
| Swipe affordance | the peek | suit indicator + a **one-shot first-run nudge** (~10 dp, ~120 ms, after deal-in, skipped under reduced motion) |
| `DeckTransform` scale/opacity/tilt/stack-drop | — | **unchanged** (already drag-scoped) |
| Deal-in geometry (`44/26 dp`, +4.5°) | tuned for a 0.92 card | **re-tune amplitude down** for a full-width card so the deal still reads without feeling like a slam |
| Deal-in, settle, count-up, shuffle, skeletons, FAB band, suit indicator | — | **unchanged** (deal-in geometry aside) |

## Decisions the design revision must nail down

1. **Peek: kill it or keep a hairline?** `viewportFraction` exactly `1.0` (max
   room, zero at-rest swipe cue) vs `~0.97` (a 5–6 dp sliver that still hints
   swipeability). This is the central trade — resolve it explicitly, ideally
   noting it should be confirmed on a device.
2. **Swipe affordance without the peek.** If the peek goes to zero, what signals
   "swipe between sections" — the one-time first-run nudge, an edge-pull on
   overscroll, and/or making the ♠♥♦♣ indicator clearly read as *tappable nav*
   (not just a position dot)? Specify it.
3. **Card identity at full-bleed.** Where do the top hairline/edge-lift and the
   corner suit pip sit when the card touches the screen edge — a few dp of inset
   so they stay visible, or the pip moved into a slim header band? Confirm the
   rounded corners are top-only.
4. **Indicator + FAB legibility over live content.** Edge-to-edge means the
   bottom suit-indicator pill and the FAB now float over scrolling numbers.
   Confirm the pill's fill/scrim and the FAB have adequate contrast, and that
   each section keeps bottom scroll padding (Dashboard's `140` is the pattern).
5. **Reduced-motion static identity.** With `MediaQuery.disableAnimations` on,
   deal-in/settle/edge-lift all collapse to off — confirm the **static** state
   (corner pip + suit indicator + flush hairline) still unmistakably reads as
   "the deck."

## Fallback (only if decision 2 fails on device)

If removing the peek makes the swipe genuinely undiscoverable and no drag-hint
recovers it, the sanctioned escalation is the **NavigationRail/bottom-nav model
already specced for tablet (§2.9)**: the floating suit pill becomes an anchored
bottom `NavigationBar` of the four suit glyphs, keeping the swipe and turning
deal/settle into page transitions. This dilutes the card *object* into a card
*theme*, so treat it as a fallback, not the plan.

## Non-negotiables (carry over)

- **Calm over casino.** Full-bleed must not tempt any celebratory flourish; no
  new motion vocabulary, no shadows (tonal depth only).
- **Reduced motion:** every animation keeps its instant/off fallback.
- Reuse existing tokens (`AppDeck`, `DeckTransform`, `DeckSurface`, `MoneyColors`,
  Manrope). Any new/changed token given in hex/dp for **both** themes.
- 60 fps mid-range Android; `transform`/`opacity` only.

## Deliverables

1. **Mockups** (light + dark) of a section at full-bleed — Dashboard and one
   more — showing the card at the screen edge, the top hairline/pip placement,
   the indicator + FAB over content, and a mid-swipe frame (drag seam + the
   outgoing card lifting).
2. A **design-handoff markdown** (same structure as the v4 handoffs) giving the
   final values for every knob above, the resolved decisions 1–5, the re-tuned
   deal-in geometry, and the reduced-motion + calm-not-casino notes. Self-
   contained — this is what I implement from.
