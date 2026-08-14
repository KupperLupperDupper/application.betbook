# BetBook — Deck personality: motion & interaction handoff

**Revision v3 — amplitude tuning.** On-device testing found v2 too quiet to register: the tilt and falloff were imperceptible, the deal-in read as an instant settle, and one counting figure left screens static. Every knob below is the tuned value; §9 lists the v2 → v3 diff. Character is unchanged — bigger amplitude, same curves, still no overshoot.

Companion to `DESIGN_HANDOFF.md`. Same tokens, same themes, nothing restyled. Read `CLAUDE.md` first — every rule there still binds, in particular **no celebration, no drama**.

Design intent: **a beautifully printed deck of cards, handled quietly.** Every item below is tactile and short. Nothing here rewards, congratulates, or dramatises. If an animation reads as "fun", it is wrong.

Visual reference: `mockups/betbook-card-motion.html` (frames for deal-in, mini-card avatar, shuffle, skeletons, count-up).
Drop-in constants: `flutter/deck_motion.dart` (durations, curves, spring, suit assignment, chip geometry).

---

## 0. Global motion rules

| Rule | Value |
|---|---|
| Reduced motion source | `MediaQuery.disableAnimationsOf(context)` — check once per widget, not per frame |
| Reduced-motion policy | **Instant final state.** No shortened animation, no fade-substitute, unless a row below says otherwise |
| Property budget | `transform` + `opacity` only. Never animate layout, shadow, blur or colour of a large fill |
| Curves used | `Curves.easeOutCubic` (entrances, settles), `Curves.easeInOutSine` (loops), `Curves.linear` (shimmer sweep only) |
| Overshoot | Forbidden everywhere. No `elasticOut`, no `bounceOut`, no `Curves.easeOutBack` |
| Haptics | `HapticFeedback.selectionClick()` only, and only on: deck settle, refresh armed. Never on save, never on a money value |
| Repaint isolation | Wrap every looping animation (`riffle`, loader, shimmer) in `RepaintBoundary` |
| Ticker hygiene | Loops stop when off-screen (`TickerMode` / `VisibilityDetector`), always on `dispose` |

`deck_motion.dart` exposes `Motion.of(context)`; when animations are disabled every duration it returns is `Duration.zero`, so most call sites need no `if`.

---

## 1. Deck section transition — "dealing through the deck"

Builds on §6 of `DESIGN_HANDOFF.md`; unchanged values are repeated so this section is implementable alone.

### 1.1 Swipe / drag

| Property | Value |
|---|---|
| Structure | horizontal `PageView`, `viewportFraction 0.92`, `clipBehavior: Clip.none`, `padEnds: true` |
| Scale | active `1.0` → neighbour `0.90`, linear in page offset |
| Opacity | active `1.0` → neighbour `0.74`, linear in page offset |
| Content parallax | card content translates `0.22 ×` the page delta, opposite the drag |
| **Stack drop** | neighbours translate `+6` dp down (`translateY = 6 × offset`), so the deck reads as a stack in depth rather than a filmstrip. This is the cheapest large gain in the whole revision — it is what makes the top card look lifted |
| **Slide tilt** | card rotates `−2.4° × offset` (radians `−0.0419 × offset`), `alignment: Alignment.bottomCenter`. Sign follows direction: the card leaving to the left tilts anticlockwise, the one entering from the right arrives from `+2.4°` and lands flat |
| **Edge lift** | the active card's 1 dp hairline (§6) interpolates opacity `0.30` (neighbour) → `1.00` (active), so the top card reads as physically on top |
| Physics | `SpringDescription(mass: 1, stiffness: 220, damping: 26)` — critically-ish damped, one settle, no wobble |
| Fling threshold | 350 px/s; below it the page springs back to the current card |
| Haptic | `HapticFeedback.selectionClick()` on settle (page index changes), **not** on drag start, **not** on snap-back |

**2.4° is the working value; 3.0° is the hard ceiling.** Read as *rotation* it is still barely nameable — it is felt as weight — but combined with the 0.90 scale, the 6 dp drop and the 0.22 parallax the gesture now clearly reads as lifting the top card off a stack. Past 3° the deck starts to read as a card-game table; do not go there, and never let tilt and stack-drop grow together beyond these values.

### 1.2 Indicator tap / programmatic jump

`animateToPage`, `Curves.easeOutCubic`, **380 ms** for an adjacent card, **440 ms** for a 2–3 card jump (do not scale further). The heavier falloff needs the extra time to stay legible; below 340 ms the tilt and drop turn into a flicker. The spring is for drags only. Same haptic on arrival.

### 1.3 Deal-in (first open)

| Property | Value |
|---|---|
| Trigger | first build of the deck shell **per app process** (cold start), and once immediately after onboarding completes. Never on hot resume, never on theme change, never when returning from a pushed route |
| Order | back of the deck first: ♣ Settings → ♦ Stats → ♥ Sites → ♠ Dashboard. The card the user will see lands **last** |
| Stagger | 110 ms per card (starts at 0 / 110 / 220 / 330 ms) — the gap is what makes it read as four separate placements rather than one block |
| Per-card duration | 460 ms, `Curves.easeOutCubic` |
| Per-card transform | from `Offset(+44, +26)` dp, `scale 0.94`, `rotation +4.5°` (`0.0785 rad`, origin `bottomCenter`), `opacity 0.0` → to rest (`Offset.zero`, `1.0`, `0°`, `1.0`) |
| Total | **790 ms** of card motion (330 + 460). Still one soft motion per card, no bounce, no settle wobble |
| Indicator | ♠♥♦♣ row fades in `opacity 0 → 1`, delay 790 ms, 200 ms, `easeOutCubic`. No stagger between suits |
| FAB | scales `0.9 → 1.0` + fades in, delay 850 ms, 180 ms, `easeOutCubic` |
| Landing cue | each card fires the settle emphasis (§1.5) as it lands — four quiet edge flickers, 110 ms apart, is the "dealt" read |
| Haptic | **none** — this is ambient, not a response to input |
| Input | the deck is interactive from frame 0; a swipe during deal-in cancels the animation to the rest state in 120 ms and hands control to the `PageView`. At 790 ms this matters more than it did at 590 — test it |
| Reduced motion | everything at rest immediately, including indicator and FAB. No fade |

### 1.4 Deck reduced-motion fallback (swipe)

`jumpToPage` on indicator tap; drag still tracks the finger (that is direct manipulation, not animation) but scale, opacity, tilt, stack drop, hairline lift and parallax are all pinned to their active values (`1.0 / 1.0 / 0° / 0 dp / 1.00 / 0`). Haptic on settle stays.

### 1.5 Settle emphasis — the landing cue

The one addition in v3. On settle (page index changes, or a deal-in card lands) the **1 dp hairline of the card that landed** brightens and returns:

| Property | Value |
|---|---|
| Motion | hairline colour `deck.hairline` → `deck.hairlineSettle` → `deck.hairline` |
| Timing | 140 ms in (`easeOutCubic`), 60 ms hold, 220 ms out (`easeOutSine`) — 420 ms total |
| Light | `#C4C6D0 @ 55%` → `#74777F @ 70%` (`outline`) |
| Dark | `#FFFFFF @ 7%` → `#FFFFFF @ 18%` |
| Scope | the border stroke only. Nothing scales, nothing moves, no fill changes, no shadow |
| Cost | one 1 dp stroke repaint inside the card's existing `RepaintBoundary` |
| Concurrency | fires with the existing `selectionClick()` haptic — the tactile and visual land together, which is most of why it registers |
| Reduced motion | not fired at all; the hairline stays at its rest value. The haptic still fires |

It is deliberately an *edge* cue: a card being placed on a stack catches light along its edge. Do not extend it to the fill, and do not add a second cue on top of it.

---

## 2. Pull-to-refresh — "shuffle"

**Dev note:** the store is local and reactive, so lists never need a fetch. Wire this to the **manual FX-rate update** on Dashboard and Sites (the only real network-free "refresh" the app has — recomputing converted totals from stored rates, and, if the user has entered rates manually, re-reading them). If a screen has no such work, the gesture must be **absent**, not decorative-and-lying: no shuffle on Stats or Settings.

### 2.1 Geometry

Four suit glyphs ♠ ♥ ♦ ♣, 14 dp, in a row, 10 dp gap, centred, in a 44 dp tall overlay. `displacement: 44`. Track colour `outline`; the emphasised suit `primary`.

### 2.2 Drag phase (0 → armed)

Driven by pull progress `p ∈ [0,1]`, no time-based animation.

| `p` | State |
|---|---|
| 0.00 | four suits stacked at centre, each rotated `±6°` alternating, `opacity 0.40` |
| 0.00 → 1.00 | glyphs spread linearly to their row positions, rotation → `0°`, `opacity 0.40 → 1.00` |
| 1.00 | even row, upright, full opacity, all in `outline`; `HapticFeedback.selectionClick()` fires once on crossing |

Over-pull past `p = 1` adds nothing (clamp) — no stretch, no growth.

### 2.3 Refresh phase (riffle loop)

| Property | Value |
|---|---|
| Motion | each suit lifts `−6` dp and returns, sequentially left → right |
| Per suit | 180 ms up-and-down, `Curves.easeInOutSine` |
| Sequence | 90 ms between suit starts → **420 ms** cycle (adjacent suits overlap), then `120 ms` pause, loop |
| Colour | lifted suit `primary`, others `outline` — cross-fade 90 ms |
| Minimum visible | 700 ms, even if the work finishes in 0 ms (below that it reads as a glitch) |
| Exit | overlay collapses height 44 → 0 in 200 ms `easeOutCubic`, glyphs fade out over the first 120 ms |
| Rest state | nothing. No persistent indicator, no "last updated" spinner. The updated FX timestamp line on the card is the receipt |

### 2.4 Reduced motion

Drag phase unchanged (finger-driven). Refresh phase: the row of four suits is shown **static**, all in `primary`, held 700 ms, then removed with no collapse animation. No lift, no colour cycling.

---

## 3. Mini playing-card site avatar

Replaces the 40 dp colour rounded-square + initial. Same information, card-shaped.

### 3.1 Geometry

| Context | Size | Radius | Rank (initial) | Pip |
|---|---|---|---|---|
| List row (Sites, transaction row's site line, pickers) | **32 × 44** dp | 6 | 17 sp / w700 | 8 dp, top-right, inset 3 |
| Site-detail hero | **64 × 88** dp | 10 | 34 sp / w700 | 14 dp, top-right, inset 6 · plus a mirrored 14 dp pip bottom-left, rotated 180° |
| Dense (chips, autocomplete) | **24 × 33** dp | 5 | 13 sp / w700 | pip **omitted** below 28 dp width |

Aspect ratio is fixed at **1 : 1.375** — never stretch. In a 64 dp list row the 44 dp chip is vertically centred with 10 dp above and below; row height does not change.

### 3.2 Colour & contrast

- Fill: the site's stored colour (from the 8-hue chart palette, §2.4 — light values in light theme, dark values in dark theme).
- Rank + pip: `#FFFFFF` when the fill's relative luminance `< 0.45`, else `#1A1B20`. Both directions clear ≥ 4.5:1 against every palette hue in both themes.
- Pip uses the **same** colour as the rank at full opacity — no tinting, no 60% pips (that is where legibility dies at 8 dp).
- 1 dp inner hairline `#000000 @ 12%` (light theme only) so a pale fill still reads as an object on white.
- Suit pip glyph: the four Unicode suits rendered from the app font at w600. `♥`/`♦` are **not** recoloured red — the fill carries the site's identity; a red pip on a red-ish site is illegible and reads as casino.

### 3.3 Suit assignment

Deterministic and stable for the life of the site, independent of list order, locale, and Dart's per-process `hashCode`:

```
suitIndex = fnv1a32(site.id) % 4        // 0 ♠  1 ♥  2 ♦  3 ♣
```

`fnv1a32` is provided in `deck_motion.dart`. Use the immutable `site.id`, never the name (renaming a site must not change its card). Duplicated suits across sites are expected and fine — the suit is texture, not an identifier.

### 3.4 Semantics

The chip is decorative and `excludeSemantics: true` inside the row; the row's label is the site name + net. Do not announce the suit.

### 3.5 Motion

None on the chip in lists. On site-detail entry the hero chip does a **single** 220 ms `easeOutCubic` `scale 0.94 → 1.0` + fade as part of the normal route transition — no flip, no rotation. Reduced motion: static.

---

## 4. Suit loader + skeletons

### 4.1 Suit loader (replaces `CircularProgressIndicator`)

Only for genuinely blocking work: CSV/JSON import, export, backup restore, first-run migration. Never for a list that is about to appear.

| Property | Value |
|---|---|
| Layout | ♠ ♥ ♦ ♣, 16 dp each, 12 dp gap, centred; optional `bodyMedium onSurfaceVariant` label 16 dp below |
| Per-suit | `opacity 0.35 → 1.00` and `scale 0.92 → 1.00`, out and back |
| Timing | 440 ms per suit, stagger 110 ms, cycle **880 ms**, `Curves.easeInOutSine`, loop |
| Colour | `primary` (`#3B5F9E` light / `#ADC6FF` dark) throughout — no colour cycling |
| Sizes | small 12 dp / 8 gap (inline, in-card) · default 16 dp / 12 gap · large 22 dp / 16 gap (full-screen) |
| Determinate work | show a 4 dp `LinearProgressIndicator` in `primary` on `surfaceContainerHighest` **instead** — a suit loader must never fake progress |
| Reduced motion | the four suits static at `opacity 1.0` in `primary`, plus the label. Nothing moves |
| Semantics | `Semantics(label: 'Indlæser' / 'Loading', liveRegion: true)` on the loader; announce completion |

### 4.2 Skeleton blocks

| Property | Value |
|---|---|
| Block fill | `surfaceContainerHigh` (`#E9E7EC` light / `#292A2F` dark) |
| Block radius | 8 for text lines, 12 for chips/avatars, 16 for card containers |
| Text-line heights | 12 (bodySmall), 16 (body/title), 28 (secondary total), 44 (hero figure) |
| Shimmer | a band 40% of the block width sweeping left → right, `1200 ms` `Curves.linear`, `400 ms` pause between sweeps, all blocks on **one shared controller** so the sweep crosses the screen as a single pass |
| Shimmer highlight | `onSurface @ 4%` light (`#1A1B20` @ 4%) / `#FFFFFF @ 6%` dark, soft edges (`stops: 0.0, 0.5, 1.0`, transparent → highlight → transparent) |
| Minimum visible | 400 ms — below that, render the real content directly and skip the skeleton entirely |
| Exit | 150 ms cross-fade skeleton → content. No slide, no stagger |
| Reduced motion | blocks render at the base fill with **no** sweep; everything else identical |
| Semantics | the skeleton subtree is `ExcludeSemantics`; the region announces "Indlæser" once |

### 4.3 Skeleton layout per screen

Widths are fractions of the content column; every block is left-aligned unless noted.

**Dashboard** — inside the deck card, screen padding 16:
1. Label line 40% × 12 · gap 12
2. Hero figure block 62% × 44 · gap 8
3. Support line 48% × 16 · gap 24
4. Two side-by-side cards, each `(50% − 6)` × 88, radius 16 (best / worst) · gap 24
5. Section label 30% × 12 · gap 12
6. Three transaction rows: 36 dp circle (radius 12) + `[52% × 16 over 34% × 12]` stacked, amount block 22% × 16 right-aligned; row height 64, divider omitted

**Sites** — 5 rows:
1. Label line 34% × 12 · gap 12
2. Per row: 32 × 44 chip block radius 6 · `[46% × 16 over 28% × 12]` · right-side `18% × 16` over `10% × 12`; row height 64
3. No FAB skeleton — the FAB renders live immediately

**Stats** — inside the deck card:
1. Label 34% × 12 · gap 12
2. Chart card 100% × 168, radius 16, with an inner baseline block 100% × 1 at 60% height in `outlineVariant` (so the empty chart still reads as a chart) · gap 16
3. Filter chip row: three blocks 64 / 88 / 72 × 32, radius 12 (full-radius pill acceptable) · gap 24
4. Two summary rows: `[40% × 16]` left, `[22% × 16]` right, height 48

---

## 5. Hero P/L count-up & zero crossing (§3.13, fully specified)

### 5.1 Count-up

| Property | Value |
|---|---|
| Trigger | screen entry (deck card becomes the active page, or route push), **and only if the formatted value differs** from the last value this screen displayed. Never on scroll, never on rebuild, never on theme change |
| Duration | **400 ms**, `Curves.easeOutCubic`, regardless of delta size |
| From → to | the previously displayed value → the new value. On first ever entry (no previous value): from `0`. On first entry with no data: no animation, render the empty state |
| Interpolation | `lerpDouble` on the raw amount, formatted every frame with the **same** formatter as the rest state (grouping, 2 decimals or 0 per locale setting, `kr` suffix) |
| Sign & icon | set to the **final** state at frame 0 and held. The digits count; the sign and arrow do not flicker |
| Colour | the final colour from frame 0 — colour never animates during a count-up (see 5.2 for the one exception) |
| Jitter | `FontFeature.tabularFigures()` is mandatory on `type.display.pl`; the block must not resize mid-count. Reserve width with the widest of {from, to} |
| Secondary figures | **now included, staggered** — see 5.3. Colour is never animated on them |
| Semantics | the animating `Text` is `ExcludeSemantics`; a sibling `Semantics(liveRegion: true)` announces the final formatted value once, after settle |
| Reduced motion | final value rendered immediately |

### 5.3 Staggered secondary figures (v3)

"One figure per screen" made every screen but the hero read as static. Secondary money figures now count too, in one wave, with hard limits so the screen never looks busy.

| Property | Value |
|---|---|
| Group | Dashboard: hero P/L (t = 0) → Deposited total → Withdrawn total → best/worst card figures. Sites: per-site nets, top to bottom. Site detail: hero net → deposited → withdrawn |
| Stagger | **90 ms** between figures on Dashboard / Site detail; **60 ms** between list rows on Sites |
| Duration | hero 400 ms; every secondary figure **280 ms**, `Curves.easeOutCubic` |
| Cap | **6 animating figures maximum**. Beyond the 6th, values render final immediately — no queue, no wave running down a long list |
| Sites list | only rows in the viewport when the card became active animate. Rows scrolled into view later render final immediately (never animate on scroll) |
| Colour & sign | set to final at frame 0 on **all** secondary figures. Only the hero may cross zero (§5.2); a secondary figure that changed sign swaps colour instantly |
| Wave total | Dashboard worst case 400 + 4 × 90 = **760 ms** — inside the same beat as the deal-in, so a cold start reads as one motion |
| Trigger | unchanged: screen entry, only for figures whose formatted value changed. A screen where only one figure changed animates only that figure |
| Semantics | the wave is `ExcludeSemantics`; one `liveRegion` announcement for the hero only, after settle |
| Reduced motion | every figure final immediately, no wave |

Not included, and not negotiable: chart series drawing on, list rows sliding in, chips or containers animating. The wave is numerals only.

### 5.2 Zero crossing

Applies when the new value's sign differs from the previously displayed value's sign (including to/from exact zero).

| Element | Motion |
|---|---|
| Total | **250 ms**, runs **concurrently** with the 400 ms count-up (starts at t = 0) |
| Colour | `Color.lerp(oldColor, newColor, t)` with `MoneyColors.neutral` forced at `t = 0.5` — a two-leg lerp `old → neutral → new`, `Curves.easeInOutSine`. Guarantees the figure passes through grey rather than smearing green into orange |
| Sign glyph | cross-fade: old `+`/`−` out over 0–110 ms, new in over 140–250 ms, `easeOutCubic`. Position is fixed (tabular), so nothing shifts |
| Trend arrow | `trending_up` / `trending_down` swap **through** `trending_flat`: old icon fades out 0–110 ms while rotating to `0°`; `trending_flat` is shown 110–140 ms at full opacity; new icon fades in 140–250 ms rotating from `0°` to its rest angle (`0°` — the M3 glyphs already carry the direction, the rotation is only ±10° of travel into place) |
| Container tint | best/worst container fills, if visible, cross-fade over the same 250 ms |
| Forbidden | flash, scale pop, bounce, colour overshoot, haptic, sound |
| Reduced motion | colour, sign, and icon all swap instantly to the final state |

Exact zero is always `neutral` + `trending_flat` + no sign (`0,00 kr`), never `+0,00`.

---

## 6. Card texture — recommendation: hairline yes, paper no

**Rejected: bitmap paper/linen noise.** At the opacity that stays calm (≤ 4%) an 8-bit noise texture bands visibly on OLED dark surfaces, survives poorly through the deck's scale interpolation (it shimmers as cards scale 0.94 → 1.0), costs a tiled image decode on every card, and reads as *grain* — screen dirt — rather than *print*. Skip it.

**Accepted: two hairlines and the existing corner pips.** They carry "printed card" through edge quality, which is where the real cue lives.

| Token | Light | Dark | Applies to |
|---|---|---|---|
| `deck.hairline` | `#C4C6D0` @ 55% (`outlineVariant`) | `#FFFFFF` @ 7% | 1 dp inset stroke on every deck card, radius 28. Opacity lifts 0.30 → 1.00 with page offset (§1.1) |
| `deck.hairlineSettle` | `#74777F` @ 70% (`outline`) | `#FFFFFF` @ 18% | peak of the 420 ms settle emphasis (§1.5) |
| `deck.topHighlight` | *none* | `#FFFFFF` @ 4% | 1 dp line along the **top edge only** of the active deck card, inside the hairline, fading to transparent at 24 dp from each corner |
| `deck.pip` | `#74777F` (`outline`) @ 70% | `#8E9099` @ 70% | existing corner suit pips, 11 dp, inset 14 — unchanged |
| `card.chipHairline` | `#000000` @ 12% | *none* | 1 dp inner stroke on mini-card avatars (§3.2) |

No highlight in light theme: on `#FAF9FC` a white top edge is invisible, and anything darker reads as a shadow, which the system forbids.

---

## 7. Reduced-motion checklist (`MediaQuery.disableAnimations == true`)

| # | Feature | Fallback |
|---|---|---|
| 1 | Deck swipe transition | scale / opacity / tilt / stack drop / parallax pinned to active values; finger tracking kept; haptic kept |
| 2 | Indicator tap | `jumpToPage`, no animation |
| 3 | Deal-in | deck, indicator and FAB at rest immediately; no fade, no landing cue |
| 3b | Settle emphasis (§1.5) | not fired; hairline stays at rest. Haptic still fires |
| 4 | Pull-to-refresh shuffle | drag spread kept (finger-driven); riffle replaced by a static row of four `primary` suits held 700 ms |
| 5 | Mini-card hero entry | static, no scale-in |
| 6 | Suit loader | four static suits at full opacity, no pulse |
| 7 | Skeletons | static blocks, no shimmer sweep |
| 8 | P/L count-up + secondary wave | every figure final immediately, no stagger |
| 9 | Zero crossing | colour, sign, icon swap instantly |
| 10 | Skeleton → content cross-fade | instant swap |

**Motion never carries meaning alone.** The lifted suit in the shuffle also has the "armed" haptic and the FX timestamp; the count-up's meaning is the number itself; the zero crossing is stated by the sign and the arrow glyph, not by the transition.

---

## 8. Accessibility summary

- All new text (rank initials, loader labels) ≥ 4.5:1; suit pips and skeleton blocks are decorative but still land ≥ 3:1 against their container.
- Mini-card avatars survive `textScaleFactor 1.3`: the chip is a fixed 32 × 44 box; the rank initial scales with text and is clipped at `1.3 ×` by `FittedBox(fit: BoxFit.scaleDown)`, never by overflow.
- Every looping animation is `ExcludeSemantics` with a single `liveRegion` sibling — screen readers get one announcement, not a stream.
- Tap targets unchanged: the mini-card avatar is inside the row's 64 dp target; suit indicator taps stay 48 dp.
- No animation exceeds 3 flashes/second at any amplitude; nothing loops faster than 420 ms per cycle.

---

## 9. v2 → v3 amplitude diff

Character unchanged: same curves, same spring, no overshoot, no new colours in the fills. Only amplitude and count.

| Knob | v2 | v3 | Why |
|---|---|---|---|
| Swipe scale | 1.0 → 0.94 | **1.0 → 0.90** | 6% was inside JND at phone size |
| Swipe opacity | 1.0 → 0.86 | **1.0 → 0.74** | pushes the neighbour back into the stack |
| Swipe tilt | −1.2° | **−2.4°** (ceiling 3.0°) | the single most-felt change; still not nameable as rotation |
| Stack drop | — | **+6 dp × offset** | new; turns a filmstrip into a stack, costs nothing |
| Parallax | 0.15× | **0.22×** | yes, raise it — it is what sells the card as a surface with contents |
| Hairline lift | 0.40 → 1.00 | **0.30 → 1.00** | more separation between top card and neighbours |
| Indicator jump | 320 / 380 ms | **380 / 440 ms** | heavier falloff needs the time to stay legible |
| Deal-in offset | (26, 14) dp | **(44, 26) dp** | visibly placed, not nudged |
| Deal-in rotation | +2.2° | **+4.5°** | reads as a card dropped from the hand |
| Deal-in scale | 0.965 | **0.94** | matches the swipe falloff |
| Deal-in per-card | 380 ms | **460 ms** | each placement is seen |
| Deal-in stagger | 70 ms | **110 ms** | four placements, not one block |
| Deal-in total | 590 ms | **790 ms** | still under the 1 s "app is slow" threshold |
| Settle emphasis | — | **new, 420 ms hairline flicker** | the deck acknowledges the landing without moving |
| Count-up | 1 figure, 400 ms | **hero 400 ms + secondaries 280 ms, 90 / 60 ms stagger, cap 6** | screens no longer read as static |

Unchanged on purpose: the deck spring (1, 220, 26), the 350 px/s fling threshold, every curve, all haptics, the refresh shuffle, the suit loader, the skeletons, the mini-card avatars, and the rejection of paper texture.

**If it still reads quiet after this, stop.** The next increments — scale below 0.90, tilt past 3°, a fill or shadow on settle, a colour cue on the wave — all cross into game-table territory, and that trade is not available.
