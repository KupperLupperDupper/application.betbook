# BetBook

Track your deposits and withdrawals across betting/gambling sites and see your **real profit or loss**. 100% local — no accounts, no cloud, nothing leaves your device (except optional public FX rates).

Android-first, built with Flutter (also configured for iOS).

## Download

Grab the latest APK from the [**Releases**](https://github.com/KupperLupperDupper/application.betbook/releases) page — each release attaches an `.apk` plus a **QR code** you can scan with your phone to download it directly. Sideloading requires "install from unknown sources".

> Releases are debug-signed until an upload keystore is configured (see [docs/RELEASE.md](docs/RELEASE.md)). That's fine for personal sideloading; set up the keystore secrets for a properly signed build.

## Features

- **Multi-currency per site**, converted to a base currency (default DKK) for aggregate totals.
- **Headline P/L** = total withdrawals − total deposits.
- **Playing-card deck navigation** — swipe horizontally between Dashboard · Sites · Stats · Settings, each a card with its own suit (♠ ♦ ♣ ♥).
- **Dashboard**: overall net result, deposited/withdrawn totals, profit-over-time sparkline, per-site summary.
- **Sites & transactions**: add sites (name, currency, colour), log deposits/withdrawals with date + note, per-site history.
- **Stats**: profit-over-time line chart, monthly net bar chart, best/worst site, date-range filters.
- **Exchange rates**: manually editable, plus optional **weekly auto-update** from the free [Frankfurter](https://frankfurter.dev) ECB API.
- **Backup**: export/import all data as JSON (round-trip) and export transactions as CSV.
- **App lock**: biometric + PIN (salted SHA-256 in secure storage).
- **Responsible gambling**: optional deposit limits and net-loss alerts, shown as a live banner.
- **Bilingual** English / Danish, chosen on first launch. **Theme** system / light / dark.

## Tech stack

| Concern | Choice |
|---|---|
| State | Riverpod 2 |
| Local DB | Drift (SQLite) |
| Navigation | go_router |
| Charts | fl_chart |
| i18n | flutter_localizations + ARB (`lib/l10n`) |
| Design | Material 3, hand-tuned schemes + Manrope (see `docs/design`) |

## Getting started

```bash
flutter pub get
dart run build_runner build          # generates Drift code (database.g.dart)
flutter gen-l10n                      # generates localization classes
flutter run -d <device>
```

Regenerate code after changing DB tables or ARB files (the two commands above).

## Building a release

Signing, GitHub Actions APK releases (with changelog + QR download), and keystore setup are documented in [docs/RELEASE.md](docs/RELEASE.md). In short: bump `version:` in `pubspec.yaml`, push a `vX.Y.Z` tag, and the workflow builds a signed APK and publishes a release with a scannable QR code.

## Project layout

```
lib/
  app/         router, root app widget, route constants
  core/        theme (design tokens), money/currency, stats math, utils
  data/        Drift database + tables, models, repositories
  providers/   Riverpod providers (core, data, settings, lock, rates)
  features/    onboarding, home (card deck), dashboard, sites,
               transactions, stats, settings, lock
  l10n/        ARB files (en/da) + generated localizations
  widgets/     shared widgets
docs/
  RELEASE.md   release + keystore guide
  design/      design handoff, tokens, mockups
```

See [CLAUDE.md](CLAUDE.md) for architecture notes and build quirks.
