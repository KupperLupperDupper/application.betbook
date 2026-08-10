# BetBook — rules for implementation

Design source of truth: `DESIGN_HANDOFF.md`; motion and card personality: `MOTION_HANDOFF.md`. Visual reference: `mockups/betbook-mockups.html` and `mockups/betbook-card-motion.html`.

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
- Deck (horizontal `PageView`): Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣.
- Pushed routes (never deck cards): Add/edit transaction, Site detail, Add/edit site, Onboarding, App lock.

## Copy voice
Plain, supportive, non-judgemental, never hyped. "You're down 1.240 kr this month" — not "Oof, rough month!" Avoid gambling jargon where a plain word works.
