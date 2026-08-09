# BetBook — design handoff

Everything needed to implement the BetBook UI in Flutter. Start with `DESIGN_HANDOFF.md`.

```
handoff/
├── CLAUDE.md                  ← read me first (rules that must hold in code)
├── DESIGN_HANDOFF.md          ← full spec: tokens, components, screens, deck, a11y
├── flutter/
│   ├── app_colors.dart        ← both ColorSchemes, hand-tuned (do NOT seed-generate)
│   ├── money_colors.dart      ← MoneyColors ThemeExtension (profit / loss / neutral)
│   ├── app_typography.dart    ← Manrope TextTheme + tabular money styles
│   ├── app_tokens.dart        ← spacing, radius, elevation, chart palette
│   └── app_theme.dart         ← assembles light/dark ThemeData
└── mockups/
    └── betbook-mockups.html   ← open in a browser: every screen, light + dark
```

## Order of work

1. Drop `flutter/` into `lib/theme/` and wire `AppTheme.light` / `AppTheme.dark` into `MaterialApp`.
2. Build the card deck (`DESIGN_HANDOFF.md` §6) — it is the navigation shell everything else lives in.
3. Build screens in this order: Dashboard → Add transaction → Sites → Site detail → Stats → Settings → Onboarding → App lock.
4. Check each screen against the matching mockup in `mockups/betbook-mockups.html` (light and dark side by side).

## Dependencies

`google_fonts` (Manrope, JetBrains Mono) · `local_auth` (app lock) · a local store (Drift / Isar / sqflite). No network layer — the app is fully offline by design.
