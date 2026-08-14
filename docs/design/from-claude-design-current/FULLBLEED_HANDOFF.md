# BetBook — Full-bleed deck (v5)

**Revision v5 — layout reclaim.** User testing: "the card page view makes the layout feel small and cramped." Cause is compounded horizontal inset, not the metaphor. This revision makes the active card edge-to-edge and pays for the lost peek with motion instead of margin. **The deck metaphor, all swipe transforms, and every other animation are unchanged** — the only motion value that changes is deal-in amplitude, because the card is now wider.

Companion to `DESIGN_HANDOFF.md` (§6 supersedes: structure, peek, indicator) and `MOTION_HANDOFF.md` (§1.3 deal-in geometry superseded; §1.1, §1.5, §2–§5 unchanged). Read `CLAUDE.md` first — every rule there still binds, in particular **calm over casino, no new motion vocabulary, no shadows**.

Visual reference: `mockups/betbook-full-bleed.html` (Dashboard light + dark, Stats dark, mid-swipe with the drag seam, first-run nudge, re-tuned deal-in loop, reduced-motion static state).

---

## 0. The audit that justifies this

On a 393 dp screen, v4 spent before drawing any content:

| Consumer | Cost | Verdict |
|---|---|---|
| `viewportFraction 0.92` peek | 31.4 dp (15.7 each side) | **reclaimed** |
| `PlayingCard` outer padding `left/right: 6` | 12 dp | **reclaimed** |
| Section header + body gutter | 40 dp (20 each side) | **kept** — legitimate reading margin |

Content column: **311 dp → 353 dp (79% → 90%)**. Card fill: 89% → 100%.

---

## 1. Final values

| Knob | v4 | **v5** |
|---|---|---|
| `AppDeck.viewportFraction` | `0.92` | **`1.0`** |
| `PageView` | `clipBehavior: Clip.none`, `padEnds: true` | **unchanged** (`Clip.none` still needed — the tilted neighbour must draw outside its viewport) |
| `PlayingCard` outer padding | `top 6 / bottom 12 / left 6 / right 6` | **`EdgeInsets.zero`** |
| `radius.deck` | `28` all corners | **`BorderRadius.vertical(top: Radius.circular(28))`** — border **and** clip |
| Card fill | `surfaceContainerLow` | **unchanged** (`#F4F3F7` / `#1A1B20`) |
| Hairline | 1 dp inset 6 | **1 dp flush, top + left + right only**, following the top radius; no bottom stroke. Colour/opacity and the `0.30 → 1.00` page-offset lift unchanged |
| `deck.topHighlight` (dark) | 1 dp top edge, fades 24 dp from corners | **unchanged colour `#FFFFFF @ 4%`**, now inset 24 dp from each corner (`left: 24, right: 24, top: 1`) |
| Corner pip | 14 sp, top 14 / right 18 | **moved into the header band** — see §3 |
| At-rest peek | 15.7 dp / side (18 ≥ 400 dp) | **0** — the peek strip widget is deleted |
| Drag seam | — | **8 dp**, page `surface` showing between cards while a drag is in flight; 0 at rest |
| Section content padding | `screenX 16` + card padding | **`horizontal: 20`** (24 at ≥ 400 dp), `bottom: 140` on every section |
| Indicator | bare glyph row, bottom 16 inside card | **opaque nav pill**, bottom 22 — see §4 |
| FAB | bottom-right 16, lifted 64 | **bottom-right 20, lifted 92** (clears the 46 dp pill + 24 gap) |
| Scale / opacity / tilt / stack drop / parallax | `.90 / .74 / −2.4° / +6 dp / 0.22×` | **unchanged** — all drag-scoped, all self-zero at rest |
| Spring, fling threshold, haptics, settle emphasis | — | **unchanged** |
| Deal-in geometry | `(44, 26)` dp · `+4.5°` · `.94` · 460 ms · 110 ms stagger · 790 ms | **`(30, 18)` dp · `+3.2°` · `.955` · 430 ms · 100 ms stagger · 730 ms** |
| First-run nudge | — | **new**, one shot — see §5 |

Two new/changed constants for `deck_motion.dart` and `app_tokens.dart`:

```dart
// app_tokens.dart
class AppDeck {
  static const double viewportFraction = 1.0;   // was 0.92 — device-confirmable knob
  static const double dragSeam = 8.0;            // new: drag-only, 0 at rest
  static const BorderRadius shape =
      BorderRadius.vertical(top: Radius.circular(28));
  static const EdgeInsets cardPadding = EdgeInsets.zero;
  static const EdgeInsets sectionPadding =
      EdgeInsets.only(left: 20, right: 20, bottom: 140);
}

// deck_motion.dart — deal-in, re-tuned for a full-width card
static const Offset dealInOffset = Offset(30, 18);   // was (44, 26)
static const double dealInRotation = 0.0559;         // rad, +3.2° — was 0.0785 (+4.5°)
static const double dealInScale = 0.955;             // was 0.94
static const Duration dealInPerCard = Duration(milliseconds: 430);   // was 460
static const Duration dealInStagger = Duration(milliseconds: 100);   // was 110
// total 730 ms (300 + 430); indicator fade delay 730, FAB delay 790
static const Duration nudgeOut = Duration(milliseconds: 120);
static const Duration nudgeBack = Duration(milliseconds: 160);
static const double nudgeDistance = -10.0;           // dp, leftward
```

---

## 2. Decision 1 — the peek is killed, not thinned

**`viewportFraction` is exactly `1.0`.**

`~0.97` was considered and rejected: 5–6 dp per side is the width of a rounded-corner artefact, not a readable "there is another card" cue. It costs back a third of the reclaimed margin at both edges while being too thin to name, so it buys no discoverability and partially re-opens the complaint that started this revision.

**Confirm on device.** `AppDeck.viewportFraction` is a single constant — a device session can try `0.97` without touching layout code. The measurement that settles it: *does a first-run user reach Sites by swiping, without tapping the indicator?* If yes at `1.0`, ship `1.0` and never revisit. Anything else is preference, not data.

Note for implementation: at `viewportFraction 1.0` the neighbour cards are fully off-screen at rest, so `Clip.none` is still required — the outgoing card's `−2.4°` tilt and `+6 dp` drop must be allowed to paint past the viewport edge during the drag, or the corner clips visibly mid-swipe.

---

## 3. Decision 3 — card identity at full bleed

**Rounded corners: top only, confirmed.** `28` on `topLeft`/`topRight`, `0` at the bottom, on both the `BorderRadius` of the border and the clip. The card bottom runs off-screen; bottom rounding could only ever show as a clipped nick above the gesture bar.

**Hairline: flush to the screen edge.** 1 dp `deck.hairline` on the top and both side edges only, following the top radius. Same tokens as v4:

| Token | Light | Dark |
|---|---|---|
| `deck.hairline` | `#C4C6D0` @ 55% | `#FFFFFF` @ 7% |
| `deck.hairlineSettle` | `#74777F` @ 70% | `#FFFFFF` @ 18% |
| `deck.topHighlight` | *none* | `#FFFFFF` @ 4% |

On a phone with rounded display corners part of the stroke sits under the bezel curve. That is correct and intended — the visible run is the two straight sides, which is where the "sheet of card at the edge" read actually lives. Do **not** inset the stroke to make the whole rectangle visible; that reintroduces the margin this revision removes.

**Pip: moved into a header band.** A **52 dp band** directly under the status bar (`top: 44` on a 393 × 852 device, `MediaQuery.padding.top` in practice), inside the card, carrying the section title (`headlineSmall`, w800) at left and the suit pip at right:

| Property | Value |
|---|---|
| Band height | 52 dp, no fill, no divider — it is layout, not a surface |
| Pip | suit glyph 15 sp, w600, `deck.pip` (`#74777F` @ 70% light / `#8E9099` @ 70% dark) |
| Pip position | trailing, `right: 20` (aligned to the content gutter), vertically centred in the band |
| Title | section name, `onSurface`, `left: 20` |

Rationale: at full bleed a 14 dp pip inset 14 lands inside the status-bar strip and, on many devices, under a rounded display corner — it either collides with the clock or disappears. In the band it is always visible, always clear of system chrome, aligned to the content gutter, and doubles as the section header's own mark. It is the *same* pip, relocated; no size, colour or count change.

---

## 4. Decision 4 — indicator + FAB legibility over live content

Edge-to-edge means both float over scrolling numbers. No scrim, no blur, no gradient (rules 9 and *calm over casino*) — the pill gets its own opaque fill instead.

**Suit indicator → nav pill.** This also carries decision 2's permanent swipe cue: it now reads as tappable navigation, not a position dot.

| Property | Value |
|---|---|
| Container | pill, radius 22, fill `surfaceContainerHigh` (`#E9E7EC` / `#292A2F`) **at full opacity**, 1 dp `deck.hairline` border, padding 6 |
| Position | bottom 22, horizontally centred, inside the active card |
| Item | 44 × 34 visual, 4 dp gap; tap target padded to 48 × 48 |
| Active item | `primaryContainer` capsule (`#D8E2FF` / `#24457A`), glyph 17 sp in `onPrimaryContainer` (`#001A41` / `#D8E2FF`) |
| Inactive item | glyph 15 sp in `outline` (`#74777F` / `#8E9099`), no fill |
| Transition | active capsule and glyph sizes cross-fade with page offset (unchanged behaviour); tap = `animateToPage` 380 / 440 ms |
| Total height | 46 dp |
| Contrast | active glyph on `primaryContainer` 11.4:1 light / 8.2:1 dark; inactive `outline` on `surfaceContainerHigh` 4.6:1 light / 4.8:1 dark. The pill fill is opaque, so no content colour can reach the glyphs |
| Semantics | each item `Semantics(button: true, selected: …, label: 'Oversigt, sektion 1 af 4')` — it is nav, so it announces as nav |

**FAB.** Unchanged spec (56 × 56, `radius.fab`, `primaryContainer` / `onPrimaryContainer`, `add` 26, one light-theme shadow), repositioned to `bottom: 92, right: 20` so it clears the pill with a 24 dp gap. Its own 1 dp hairline in dark theme is kept — that is what separates it from content there.

**Scroll padding.** `bottom: 140` on every section's scroll view (Dashboard's existing value, now the pattern): 22 pill inset + 46 pill + 24 gap + 48 breathing. Content scrolls fully out from under both the pill and the FAB; nothing is permanently obscured.

---

## 5. Decision 2 — swipe affordance without the peek

Three cues, in order of how much load they carry:

**1. The nav pill (permanent).** §4. It looks pressable, so the four sections are always discoverable even if the swipe never is.

**2. The first-run nudge (one shot).**

| Property | Value |
|---|---|
| Motion | active card translates `−10` dp on X and returns. Nothing else moves — no tilt, no scale, no seam widget |
| Timing | 120 ms out `easeOutCubic`, 160 ms back `easeOutCubic`, no hold |
| Trigger | once ever per install, 240 ms after deal-in settles (t ≈ 970 ms from cold start), only if the user has not swiped during deal-in. Persisted flag `deck.nudgeShown` |
| Never | not on later launches, not after onboarding replay, not on section change, not if the user already swiped |
| Reduced motion | not fired at all. The pill carries the cue |
| Haptic | none |

**3. The drag seam (on every drag).** While a drag or fling is in flight the two cards separate by up to **8 dp**, revealing the page `surface` between them — the deck's own edges become the cue at exactly the moment the user is asking the question. It is not a widget: it is `8 × dragProgress` added to the page offset translation, and it is `0` at rest, so it costs no layout. Under reduced motion it still appears, because it is finger-driven, not animated.

**Overscroll at the ends:** the platform stretch only. No custom edge-pull, no glow — that would be new motion vocabulary.

---

## 6. Re-tuned deal-in

The v3 geometry was tuned against a 341 dp card. At 393 dp the same offset and rotation sweep the card's corner noticeably further, and it reads as a slam rather than a placement — louder is not the goal, *legible* is.

| Property | v3 | **v5** | Why |
|---|---|---|---|
| Offset | `(44, 26)` dp | **`(30, 18)`** | ~32% down; travel-as-fraction-of-card-width is preserved |
| Rotation | `+4.5°` (`0.0785 rad`) | **`+3.2°`** (`0.0559 rad`) | corner sweep at 393 dp matches what 4.5° gave at 341 dp |
| Scale | `.94` | **`.955`** | a full-width card scaling from .94 crosses the screen edge twice |
| Per card | 460 ms | **430 ms** | shorter travel, same perceived speed |
| Stagger | 110 ms | **100 ms** | keeps four distinct placements inside 730 ms |
| Total | 790 ms | **730 ms** | 300 + 430 |
| Indicator fade | delay 790, 200 ms | **delay 730**, 200 ms | unchanged character |
| FAB scale-in | delay 850, 180 ms | **delay 790**, 180 ms | unchanged character |
| Origin | `bottomCenter` | **unchanged** | |
| Curve, order (♣ ♦ ♥ ♠), landing cue, no haptic, cancel-on-swipe 120 ms | — | **unchanged** | |

Cards deal to the **flush** rest geometry, so each placement finishes edge-to-edge, not inset. Everything else in `MOTION_HANDOFF.md` — settle emphasis (§1.5), refresh shuffle, mini-card avatars, suit loader, skeletons, count-up wave, zero crossing — is untouched by this revision.

---

## 7. Reduced motion — the static deck (decision 5)

With `MediaQuery.disableAnimations == true`: no deal-in, no settle flicker, no nudge; the seam still appears under a real finger (direct manipulation). What must carry "this is a deck", verified in the mockup:

1. **Top-only 28 dp radius** reading against the page `surface` (`#FAF9FC` / `#121318`) at the two top corners — the single strongest static cue, and the reason the radius must not go to 0.
2. **Flush hairline** at full rest opacity on top and both sides.
3. **Suit pip** in the header band.
4. **Four-suit nav pill** at the bottom.

That is four simultaneous, non-motion signals; the deck is not motion-dependent. All other reduced-motion fallbacks in `MOTION_HANDOFF.md` §7 apply unchanged, plus:

| # | Feature | Fallback |
|---|---|---|
| 11 | First-run nudge | not fired, flag still set (so it never fires later either) |
| 12 | Drag seam | kept — finger-driven, not animated |

---

## 8. Calm-not-casino check

Full bleed is a *removal*, and nothing was added to compensate except one 10 dp nudge and 8 dp of seam. Explicitly **not** done, and not available later: a shadow under the active card, a fill or scale on settle, a card-back pattern on the exposed page surface, a fanned multi-card preview, a scrim behind the pill, any colour on the seam. The card got bigger; the deck did not get louder.

---

## 9. Fallback (only if decision 2 fails on device)

If a first-run user cannot find the swipe and the nudge does not recover it, the sanctioned escalation is the tablet model from `DESIGN_HANDOFF.md` §2.9: the pill becomes an anchored bottom `NavigationBar` of the four suit glyphs, swipe retained, deal/settle become page transitions. This dilutes the card *object* into a card *theme* — treat it as an escalation with the owner in the room, not a fix.

---

## 10. Supersedes

- `DESIGN_HANDOFF.md` §6: **Structure** (viewportFraction, card margin, radius, pip position), **Peek** (deleted in full), **Indicator** (now the nav pill of §4). Transition, Physics, Dark theme, Semantics stand.
- `MOTION_HANDOFF.md` §1.3: deal-in geometry and timings per §6 above. §1.1, §1.2, §1.4, §1.5 and §2–§8 stand.
- `DESIGN_HANDOFF.md` §2.9 responsive: "deck peek → 18 dp at ≥ 400 dp" is void; instead `sectionPadding` horizontal `20 → 24` at ≥ 400 dp.
