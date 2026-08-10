# Claude Design brief — make the BetBook deck motion more *felt*

Paste into Claude Design. This is a **tuning revision** of the existing motion
spec, not a new feature. Read `MOTION_HANDOFF.md` and `flutter/deck_motion.dart`
from the v2 handoff first — you are adjusting those values, nothing else.

## Problem (from on-device testing)

The deck personality is implemented exactly to spec, but on a real phone the
motion is **too quiet to be noticed**. Specifically:
- The swipe **tilt (−1.2°)** and the scale/opacity falloff are imperceptible in
  normal use.
- The **deal-in** reads as an almost-instant settle; users don't register that
  the cards were "dealt."
- Only one figure (the hero P/L) counts up, so most screens feel static.

The user wants the deck to feel **tactile and clearly alive** — you should still
be able to tell it's a *quiet, well-printed deck*, but the motion must actually
register. **Do NOT cross into casino/game-table territory** (no overshoot,
bounce, confetti, celebration, sound). The bar is "noticeably tactile," not
"fun."

## Current baseline (from deck_motion.dart) — revise these

| Knob | Current | Notes |
|---|---|---|
| Swipe scale (active→neighbour) | 1.0 → 0.94 | |
| Swipe opacity | 1.0 → 0.86 | |
| Swipe tilt | −1.2° × offset | you warned ≥3° reads as a card table |
| Deal-in from-offset | (26, 14) dp | |
| Deal-in from-scale | 0.965 | |
| Deal-in from-rotation | +2.2° | |
| Deal-in stagger / per-card | 70 ms / 380 ms (total ~590 ms) | |
| Indicator jump | 320 ms adjacent / 380 ms far | |
| Count-up | 400 ms, exactly one figure per screen | |

## What to deliver

Revised values that make the motion clearly perceptible while staying calm.
Please decide the exact numbers, but address each:

1. **Swipe** — a stronger sense of lifting the top card off a stack: more scale
   and opacity falloff on the neighbour, and a tilt large enough to feel without
   reading as a table (you set the ceiling — you previously flagged 3°). Say
   whether the parallax should increase too.
2. **Deal-in** — make it clearly a *deal*: larger entry offset/rotation and/or a
   longer per-card duration and stagger so each card is visibly placed. Keep it
   one soft motion per card (no bounce). Give the new total.
3. **Count-up** — reconsider the "one figure per screen" rule: should the
   Deposited/Withdrawn totals and per-site nets also count up (staggered)? If
   yes, specify the stagger and how to avoid a busy screen. Keep tabular, no
   colour flashing.
4. **Optional new cue** — if a small, calm addition would help the deck feel
   alive on settle (e.g. a brief hairline/edge emphasis on the card that lands),
   propose it. Skip if it risks noise.

## Hard constraints (unchanged)

- Calm-not-casino; no overshoot/`elasticOut`/`bounceOut`/`easeOutBack`, no
  celebration, no sound. Haptic only on deck settle + refresh-armed.
- **Reduced-motion fallback for every value** (`MediaQuery.disableAnimations`)
  — restate them if they change.
- `transform`/`opacity` only; 60 fps on mid-range Android.
- Reuse the existing tokens/themes; don't restyle anything.

## Output

1. An updated **motion values table** (the knobs above, new numbers + curves).
2. An updated **`deck_motion.dart`** (or a clear diff of the constants) I can
   drop in — durations, curves, deal-in geometry, count-up stagger.
3. A short note on what changed and why, and the reduced-motion fallbacks.
