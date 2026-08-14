# BetBook — rules for implementation

Design source of truth: `DESIGN_HANDOFF.md`; motion and card personality: `MOTION_HANDOFF.md`; **deck layout (v5, full-bleed — supersedes `DESIGN_HANDOFF.md` §6 and `MOTION_HANDOFF.md` §1.3): `FULLBLEED_HANDOFF.md`**; features: `TAGS_HANDOFF.md`, `QUICKADD_HANDOFF.md`, `NOTIFICATIONS_HANDOFF.md`. Visual reference: `mockups/betbook-mockups.html`, `mockups/betbook-card-motion.html`, `mockups/betbook-full-bleed.html`.

## Product
BetBook tracks deposits and withdrawals across betting sites so a person can see honestly whether they are up or down. **100% local** — no accounts, no cloud, no analytics, no ads, no network calls.

## Hard rules — do not violate

1. **Money colour only on net figures.** Overall P/L, per-site net, chart series, best/worst cards. Individual deposit/withdrawal amounts render in `onSurface` — they are neutral cash movements, not outcomes.
2. **Never colour alone.** Every money figure = sign (`+`/`−`) + directional icon + colour. Chart series also carry marker shapes.
3. **No celebration, no drama.** No confetti, coins, streaks, sounds, or sympathetic animation. Gains are calm; losses are honest and never mocking.
4. **Nothing that encourages depositing.** No prompts to add a deposit, no gamified limits, no "keep going" copy.
5. **Responsible-gambling tools stay easy to find** in Settings, worded supportively.
6. **Use the ColorSchemes as given.** Do not regenerate from a seed — the greys are hand-tuned. `useMaterial3: true`, `shadowColor: Colors.transparent` in dark.
7. **Tabular figures on every money style** (`FontFeature.tabularFigures()`) so columns and totals never jitter.
8. **Danish first-class.** Danish strings run 15–35% longer than English. No width-constrained label, chip, or button — chips wrap, icons drop before text.
9. **Performance:** flat fills and tonal elevation. No gradients, no blurs, one shadow in the whole app (the FAB, light theme only). Charts are `CustomPainter`, no chart package with heavy effects.
10. **A11y:** 48 dp minimum tap targets, layouts survive `textScaleFactor 1.3`, honour `MediaQuery.disableAnimations`.
11. **Every animation ships with its reduced-motion fallback** in the same commit (`MOTION_HANDOFF.md` §7). Use `Motion.of(context)` from `flutter/deck_motion.dart` — it returns `Duration.zero` when animations are disabled. No overshoot curves anywhere; no haptic except deck settle and refresh-armed.

## Navigation shape
- Deck (horizontal `PageView`, `viewportFraction 1.0` — the active card is full-bleed, zero at-rest peek, 8 dp drag-only seam): Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣. The suit indicator is a tappable nav pill, not a position dot.
- Pushed routes (never deck cards): Add/edit transaction, Site detail, Add/edit site, Onboarding, App lock, Tags, Take a break.
- Sheets (never routes): quick-add, repeat-last confirm, tag picker, site picker, notification rationale.

## Feature rules that are easy to get wrong
- **Quick-add and repeat-last write through the same repository method as the full editor.** One validation path, one Undo path. Never a parallel insert.
- **Amount presets are recall, not suggestion**: last 3 distinct amounts for the selected site, recency order. Never round numbers, never "most used", never sorted by size.
- **Repeat-last always confirms.** No one-tap commit anywhere.
- **Tags are neutral chips** with an optional dot from a 6-hue palette containing no green and no orange-red. Colour belongs to money and site identity.
- **The tag filter never persists across cold start** (the range does). A remembered filter makes a partial figure look like a total.
- **Notifications are opt-in, local, and capped**: 80% and 100% once each per period, one weekly summary. No escalation, no repeats. In-app limit banners show regardless of notification permission.
- **The limit banner is a state** (no dismiss); the weekly summary card is a message (dismissible).

## Copy voice
Plain, supportive, non-judgemental, never hyped. "You're down 1.240 kr this month" — not "Oof, rough month!" Avoid gambling jargon where a plain word works.
