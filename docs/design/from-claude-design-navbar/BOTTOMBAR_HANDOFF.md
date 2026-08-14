# BetBook — Bottom bar (v6)

**Revision v6 — one bar.** The bottom of the deck carried two objects: the v5 nav pill (§4 of `FULLBLEED_HANDOFF.md`) and a separate corner FAB. This revision merges them into a single anchored bar — `♠ ♥ (+) ♦ ♣` — carrying section feedback and the primary add action. The four suits stay the indicators, they stay tappable, and on sections with no add action the plus animates out while **the bar contracts around it** — 304 → 232 dp, the two pairs closing symmetrically toward the centre.

Companion to `DESIGN_HANDOFF.md` and `MOTION_HANDOFF.md`; supersedes `FULLBLEED_HANDOFF.md` §4 in full (see §7). Read `CLAUDE.md` first — **calm over casino, no new motion vocabulary, no shadow beyond the one FAB shadow** all still bind. The centred plus inherits that single shadow; it is not a second one.

Visual reference: `mockups/betbook-bottom-bar.html` — Dashboard ♠ light with the plus, Stats ♦ dark without it, all four bar states in both themes, the mid-transition frame, and a live show/hide loop.

---

## 1. Resolved decisions

### 1.1 Decision 1 — the suits are the dots

**Keep the suit glyphs.** In BetBook the suit *is* the section's name: it is on the header pip, in the empty-state mark, and in the app icon. Replacing four suits with four dots removes information and introduces a second position language that says less. The calm gain the owner is after comes from deleting the FAB and the active capsule, not from deleting meaning — and at 15 sp `outline` the resting glyphs are already quieter than a typical filled page dot.

Four indicators, one centre button. Non-negotiably four: the deck has four sections and the bar must not imply a fifth.

### 1.2 Decision 2 — layout and active state

`♠ ♥  (+)  ♦ ♣` — Dashboard/Sites left, Stats/Settings right, in deck order, so left-to-right still maps to swipe direction.

| Property | Value |
|---|---|
| Indicator item | **48 × 48 dp**, visual box = tap target |
| Gap between items in a pair | **4 dp** |
| Centre gap — with the button | **20 dp** each side of it |
| Centre gap — without the button | **10 dp** each side of the zero-width centre slot — the pairs meet across **20 dp** |
| Resting glyph | **15 sp, w600**, `outline` (`#74777F` / `#8E9099`) |
| Active glyph | **17 sp, w700**, `primary` (`#3B5F9E` / `#ADC6FF`) |
| Active underline | **10 × 3 dp**, radius 2, **5 dp** below the glyph, `primary` |
| Resting underline slot | reserved and empty — nothing shifts vertically when active changes |

**No capsule.** v5's `primaryContainer` capsule sitting next to a `primaryContainer` button read as two buttons of unequal size. The bar now has exactly one filled element and it is the action. Active reads by three redundant channels — size, weight+underline, colour — so it never depends on hue.

### 1.3 Decision 3 — the indicators are tappable

**Yes.** Swipe stays the primary section switch, but a swipe-only bar makes horizontal drag the *only* route between sections, and horizontal drag is precisely what fails for switch access, TalkBack linear navigation and limited motor range. Behaviour is v5's, unchanged: tap → `animateToPage`, **380 ms** for one page / **440 ms** across two, existing curve. Each item is `Semantics(button: true, selected: …)`.

### 1.4 Decision 4 — add-button show / hide, and the bar contracts with it

**The plus fades down; the bar closes over it.** One `AnimationController` drives three tweens so nothing lags: the button, the centre gap, and the bar's width.

| Property | Value |
|---|---|
| Button out | `opacity 1 → 0`, `translateY 0 → +40 dp` — **vertical only**, no scale, no horizontal component |
| Centre gap | `20 → 10 dp` each side; the centre slot itself `52 → 0` |
| Bar width | `304 → 232 dp`, centred — each pair travels 36 dp inward |

Width arithmetic at both ends: expanded `6 + 100 + 20 + 52 + 20 + 100 + 6 = 304`; collapsed `6 + 100 + 10 + 0 + 10 + 100 + 6 = 232`; t = 0.5 `6 + 100 + 15 + 26 + 15 + 100 + 6 = 268`. The centre slot keeps existing at zero width, so the row never changes child count and the two centre gaps interpolate symmetrically.

**The plus travels on one axis.** It is centred on the collapsing centre slot rather than laid out by it (`Align(alignment: Alignment.center)` inside the animated-width slot, not a child that the shrinking box pushes around) — otherwise the width tween drags it sideways as the walls close. +40 dp carries a 52 dp circle out through the bar's lower edge as it fades. It does **not** scale — a shrinking circle reads as the button being dismissed rather than stowed — and it has **no horizontal component**: the pairs are already moving inward, and a diagonal exit would make one action read as three directions. The bar does not clip its children, so the last frames of the drop are visible below its edge at low opacity; that is intended, and is why the drop is paired with the fade rather than a clip.
| Out duration / curve | **200 ms**, `easeOutCubic` |
| In | exact reverse |
| In duration / curve | **220 ms**, `easeOutCubic` |
| Overshoot | none, either direction |
| Transform origin | centre |
| Trigger | page offset crosses **0.5** toward a neighbour; `hasAddAction(nearestPage)` |
| Controller | its own `AnimationController` — a half-swipe that snaps back returns the button instead of flickering it |
| Haptic | none |

Rejected: **morph** (implies the plus *became* something; nothing replaces it) and **slide off-screen** (needs travel past the bar's own edge, which reads as a drawer opening — new vocabulary).

**The bar re-spaces; the suits ride it.** Holding position would leave a 52 dp void in the middle of a four-item bar — a hole where a button used to be, which is exactly the "something is missing" read. Contracting keeps the bar honest at both sizes: 304 dp with the action, 232 dp without, always centred, always symmetrical.

What keeps it calm is that **the glyphs are not independently animated**. They are laid out by the bar and inherit its width, so this is one object narrowing by 36 dp per side, not four targets relocating. Order and spacing inside each pair never change, and the bar's centre line never moves. Nothing scales, nothing rotates, nothing overshoots.

At t = 0.5 the frame is: bar 268 dp, centre gap 15 each side, plus at `opacity .42 / translateY 20`, pairs 18 dp in from their expanded position.

**Composition with deal-in.** The whole bar — pill, suits, plus — fades in as **one layer, 200 ms at delay 730 ms**, on the existing indicator-fade slot. The v5 separate FAB scale-in at delay 790 ms is **deleted**; the plus is part of the bar and must not arrive twice.

**Reduced motion** (`MediaQuery.disableAnimations`): the controller jumps to its end value at the same 0.5 crossing — the bar is 304 or 232 dp with no interpolation, the plus is present or absent, the active mark switches instantly. The jump resizes one centred pill floating over content; it is not a page reflow. No section content moves, and scroll padding (§6) is sized for the wider state, so nothing shifts underneath either. That instant resize **is** the fallback — do not substitute a fade.

---

## 2. The bar container

Anchored bottom, over the full-bleed scrolling card. No scrim, no blur, no gradient — the bar is **opaque**, exactly as the v5 pill was.

| Property | Value |
|---|---|
| Size | **304 × 64 dp** with the add button, **232 × 64 dp** without — the bar hugs its content rather than stretching edge-to-edge, so no fill runs under the rounded display corners or the gesture bar |
| Width transition | 200 ms out / 220 ms in `easeOutCubic`, one controller shared with the add button (§1.4) |
| Radius | **32** (full height) |
| Internal padding | **6 dp** all round |
| Position | horizontally centred; `bottom: max(20, MediaQuery.viewPadding.bottom)` |
| Clear of screen edge | expanded: 28 dp each side at 360 dp width, 44.5 at 393. Collapsed: 64 / 80.5 |
| Fill | `surfaceContainerHigh` — `#E9E7EC` / `#292A2F`, **full opacity** |
| Border | 1 dp `deck.hairline` — `#C4C6D0` @ 55% / `#FFFFFF` @ 7% |
| Elevation | tonal only (the fill *is* the elevation); no shadow on the bar in either theme |
| Height at `textScaleFactor 1.3` | unchanged — the bar is not text-metric-driven; glyph scaling is clamped at 1.15 |

Contrast on the bar fill: active glyph **5.1:1** light / **7.4:1** dark; resting glyph **4.6:1** / **4.8:1**. The fill is opaque, so no content colour can reach the glyphs.

---

## 3. The centre add button

| Property | Value |
|---|---|
| Size / shape | **52 × 52 dp, circular** (radius 26) |
| Placement | inside the bar, 6 dp of bar padding around it — **not** raised, **not** notched |
| Container / glyph | `primaryContainer` / `onPrimaryContainer` — `#D8E2FF` / `#001A41`, dark `#24457A` / `#D8E2FF` |
| Glyph | Material Symbols Rounded `add`, **26 dp** |
| Shadow | light: `0 2 4 rgba(0,0,0,.18)` — the system's one allowed shadow, inherited from the FAB. Dark: **no shadow**, 1 dp `#FFFFFF @ 7%` hairline instead |
| Pressed | 12% `onPrimaryContainer` state layer, `scale 0.97`, 80 ms in / 120 ms out |
| Focused | 3 dp `onPrimaryContainer` outline, offset 2 |
| Disabled | **never** — sections without an add action do not have the button at all |
| Tap target | 52 dp (≥ 48), no extra padding needed |
| Action | Dashboard → add transaction · Sites → add site · Stats, Settings → absent |

**Why not raised or notched:** a lifted centre button needs either a notch cut in the fill or a floating orb with its own elevation. Both are the shape language of a "big action" bar, and in a gambling ledger a centred lifted circle is exactly the slot-machine read to avoid. Inside the bar, the silhouette stays one calm pill.

---

## 4. Section indicators — transition

The active mark cross-fades against page offset, unchanged in character from the v5 pill: glyph size interpolates 15 → 17 sp, weight 600 → 700, colour `outline` → `primary`, and the underline fades 0 → 1 opacity in step. At offset 0.5 both neighbouring suits sit at half. The indicator row listens to the `PageController` directly and does not rebuild the bar.

Reduced motion: instant switch at the 0.5 crossing, no cross-fade.

---

## 5. Accessibility & semantics

- **Traversal order** is visual order: ♠ ♥ → plus → ♦ ♣, inside one `Semantics` container. The plus is announced third, in place, not hoisted first.
- **Indicators:** `Semantics(button: true, selected: isActive, label: 'Oversigt, sektion 1 af 4' / 'Dashboard, section 1 of 4')`. Selected state is spoken, so the underline is redundancy rather than the sole cue.
- **Add button:** `Semantics(button: true, label: …)` with its real action — "Tilføj transaktion" / "Add transaction" on Dashboard, "Tilføj spillested" / "Add site" on Sites. Never a generic "add".
- **When absent** the button is removed from the tree entirely, not hidden — `ExcludeSemantics` on a still-focusable target is worse than nothing.
- **Targets:** 48 dp per suit, 52 on the plus, no overlap, 304 dp total inside a 360 dp minimum screen.
- **Localisation:** nothing in the bar is on-screen text, so en/da is a semantics-label concern only and clipping is impossible.
- **Performance:** the button is `opacity` + `transform` only. The contraction is a width tween on one `Align`-ed container holding a `Row` of five fixed-size, text-free children — a genuine layout pass per frame, but on the smallest subtree in the app and the only such tween in it. Everything else in BetBook stays transform/opacity. No rebuild of the bar on swipe; the indicator listens to the `PageController` directly. 60 fps on a mid-range Android, portrait, is the measured target — if it misses, step the width in 4 dp increments, never re-add the corner FAB.
- **Semantics during the transition:** the tree flips once at the 0.5 crossing, not per frame — TalkBack is never handed a half-present button.

---

## 6. Scroll clearance

`20` bottom inset + `64` bar + `56` breathing = **140**. `AppDeck.sectionPadding.bottom` stays **140**, unchanged from v5 — the taller bar is paid for out of the old FAB's 24 dp gap. Every section's scroll view still scrolls its content fully out from under the bar; nothing is permanently obscured. **No section needs re-padding.**

---

## 7. Supersedes / unchanged

**Superseded — delete these:**

- `FULLBLEED_HANDOFF.md` **§4 in full**: the nav pill (`DeckNavPill`, fill, capsule, 46 dp height, bottom 22) and the FAB paragraph (`bottom: 92, right: 20`).
- `DESIGN_HANDOFF.md` **§3.3 FAB** as it applies to deck sections, including the **extended "Add site" FAB** on Sites — Sites now uses the same centred plus and the label moves into the semantics label. §3.3 still describes the FAB on pushed routes (Site detail).
- `MOTION_HANDOFF.md` / `FULLBLEED_HANDOFF.md` §6: the **FAB scale-in at delay 790 ms** is deleted; the bar fades in at delay 730 ms as one layer.

**Explicitly unchanged:** the deck metaphor, `viewportFraction 1.0`, top-only 28 dp radius, flush hairline, header band and suit pip, every swipe transform (scale / opacity / tilt / stack drop / parallax), the 8 dp drag seam, spring and fling physics, settle haptic and emphasis, the first-run nudge, deal-in geometry and order (♣ ♦ ♥ ♠), count-up, zero crossing, refresh shuffle, mini-card avatars, suit loader, skeletons, and all pushed routes.

**Reduced-motion inventory** gains one row and loses none:

| # | Feature | Fallback |
|---|---|---|
| 13 | Add-button show/hide | instant present/absent at the 0.5 offset crossing; no fade, no drop, no reflow |

The four static deck cues of `FULLBLEED_HANDOFF.md` §7 all survive; cue 4 is now "four-suit **bottom bar**" instead of "four-suit nav pill".

---

## 8. Constants

```dart
// app_tokens.dart
class AppBottomBar {
  static const Size    size          = Size(304, 64);   // with the add button
  static const Size    sizeCollapsed = Size(232, 64);   // without it
  static const double  radius        = 32;
  static const EdgeInsets padding    = EdgeInsets.all(6);
  static const double  bottomInset   = 20;   // max(this, viewPadding.bottom)
  static const double  itemSize      = 48;
  static const double  itemGap       = 4;
  static const double  centreGap     = 20;   // each side of the button
  static const double  centreGapTight = 10;   // between the pairs, button away
  static const double  glyphResting  = 15;
  static const double  glyphActive   = 17;
  static const Size    underline     = Size(10, 3);
  static const double  underlineGap  = 5;
  static const double  addSize       = 52;   // circular, radius = addSize / 2
  static const double  addGlyph      = 26;
  static const double  glyphScaleMax = 1.15; // textScaleFactor clamp
}

// deck_motion.dart
static const Duration addOut        = Duration(milliseconds: 200);
static const Duration addIn         = Duration(milliseconds: 220);
static const Curve    addCurve      = Curves.easeOutCubic;
static const double   addHiddenDy    = 40.0;   // dp, straight down — no scale tween
static const double   addSwitchAt    = 0.5;    // page-offset threshold
// one controller drives button opacity/scale/dy, centreGap and bar width together
static const Duration barFadeDelay   = Duration(milliseconds: 730); // was: indicator 730 + FAB 790
static const Duration barFade        = Duration(milliseconds: 200);
// deleted: fabScaleInDelay (790), fabScaleIn (180)
```

---

## 9. Calm-not-casino check

The bottom of the screen went from **two objects to one**, from two shadows-worth of visual weight to one, and from an active `primaryContainer` capsule plus a `primaryContainer` FAB to a single filled element. Nothing was added: no notch, no lift, no ring, no colour on the indicators beyond the theme's `primary`, no motion vocabulary that did not already exist (a fade plus a single-axis translate, both already in the deck's vocabulary; the width tween is a resize, not a new gesture). The bar is smaller than what it replaces — and on Stats and Settings, where there is nothing to add, it is smaller still: **232 dp, 72 narrower than its widest state**.

---

## 10. Open, for device confirmation

With the plus centred, the right thumb's rest position no longer sits on it — on 393 dp the centre is ~17 dp further from a right-handed thumb than the old corner FAB. That is comfortably inside reach and it buys a bar that behaves identically left-handed. If add-transaction frequency drops measurably after release, the sanctioned escalation is a **wider bar with the plus offset right**, not a return of the corner FAB.
