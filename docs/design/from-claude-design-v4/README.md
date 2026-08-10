# BetBook — design handoff

Everything needed to implement the BetBook UI in Flutter. Start with `DESIGN_HANDOFF.md`.

```
handoff/
├── CLAUDE.md                  ← read me first (rules that must hold in code)
├── DESIGN_HANDOFF.md          ← full spec: tokens, components, screens, deck, a11y
├── MOTION_HANDOFF.md          ← deck personality: deal-in, shuffle, card avatars, loaders, count-up
├── TAGS_HANDOFF.md            ← tags on transactions + tag-filtered Stats
├── QUICKADD_HANDOFF.md        ← quick-add sheet + repeat-last
├── NOTIFICATIONS_HANDOFF.md   ← weekly summary + limit warnings, in-app surfaces, take a break
├── flutter/
│   ├── app_colors.dart        ← both ColorSchemes, hand-tuned (do NOT seed-generate)
│   ├── money_colors.dart      ← MoneyColors ThemeExtension (profit / loss / neutral)
│   ├── app_typography.dart    ← Manrope TextTheme + tabular money styles
│   ├── app_tokens.dart        ← spacing, radius, elevation, chart palette
│   ├── deck_motion.dart       ← durations, curves, spring, suit assignment, chip geometry
│   └── app_theme.dart         ← assembles light/dark ThemeData
└── mockups/
    ├── betbook-mockups.html   ← open in a browser: every screen, light + dark
    ├── betbook-card-motion.html ← motion frames: deal-in, shuffle, skeletons, count-up
    └── betbook-features.html   ← tags, quick-add, notifications (light + dark)
```

## Order of work

1. Drop `flutter/` into `lib/theme/` and wire `AppTheme.light` / `AppTheme.dark` into `MaterialApp`.
2. Build the card deck (`DESIGN_HANDOFF.md` §6 + `MOTION_HANDOFF.md` §1) — it is the navigation shell everything else lives in.
3. Build screens in this order: Dashboard → Add transaction → Sites → Site detail → Stats → Settings → Onboarding → App lock.
4. Check each screen against the matching mockup in `mockups/betbook-mockups.html` (light and dark side by side), and each animation against `MOTION_HANDOFF.md` — every item there needs its reduced-motion fallback (§7) in the same commit.

## Feature specs

`TAGS_HANDOFF.md`, `QUICKADD_HANDOFF.md` and `NOTIFICATIONS_HANDOFF.md` are each self-contained and independent of one another — build them in any order after the core screens. Each states its own decisions, new tokens (hex, both themes), states, reduced-motion fallbacks and EN/DA copy. Frames for all three are in `mockups/betbook-features.html`.

## Dependencies

`google_fonts` (Manrope, JetBrains Mono) · `local_auth` (app lock) · a local store (Drift / Isar / sqflite). A local-notifications plugin for the reminders in `NOTIFICATIONS_HANDOFF.md` (local scheduling only, `POST_NOTIFICATIONS`). No network layer otherwise — the app is fully offline by design.
