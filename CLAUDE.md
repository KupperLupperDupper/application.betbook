# CLAUDE.md — BetBook

Local-first Flutter app to track gambling deposits/withdrawals and see profit/loss. Android-first.

## Architecture

- **State**: Riverpod 2 (`Notifier`/`StreamProvider`/`Provider`). No codegen for Riverpod.
- **DB**: Drift (SQLite) in `lib/data/database/`. Tables: `Sites`, `Transactions`, `ExchangeRates`.
  - Money is stored in **minor units (int, 2 decimals)** — never floats. See `lib/core/money/`.
  - `Transactions.type` is an `intEnum<TransactionType>` — never reorder the enum.
- **Repositories** (`lib/data/repositories/`) wrap the DB with domain ops; exposed via providers in `lib/providers/core_providers.dart`.
- **Derived data**: `portfolioProvider`, `rgStatusProvider`, `rateMapProvider` in `lib/providers/data_providers.dart`; pure math in `lib/core/stats/`.
- **Settings**: SharedPreferences via `SettingsRepository` + `settingsProvider` (a `Notifier<AppSettings>`). `sharedPreferencesProvider` is **overridden in `main()`**.
- **Navigation**: go_router (`lib/app/router.dart`). Home is `HomeShell` — a `PageView` of playing cards (`lib/features/home/`). Onboarding gate via redirect; **app-lock gate is an overlay** in `lib/app/app.dart` (Stack over the router), re-locking on lifecycle pause.
- **Theme**: design tokens in `lib/core/theme/` (`app_colors`, `app_typography` [Manrope via google_fonts], `app_tokens`, `money_colors`, `app_theme`). Profit/loss/neutral come from the `MoneyColors` ThemeExtension — access via `context.money`. Never seed-generate the ColorScheme; the schemes are hand-tuned.
- **l10n**: ARB in `lib/l10n/` (`app_en.arb`, `app_da.arb`), generated into `lib/l10n/` (see `l10n.yaml`, `output-dir`). Access via `context.l10n` (`l10n/l10n_ext.dart`). **Never hardcode user-facing strings.**

## Codegen — run after editing tables or ARB

```bash
dart run build_runner build     # Drift (database.g.dart)
flutter gen-l10n                # localizations
```

## Conventions

- Material 3, `const` where possible, `.withValues(alpha:)` (not `.withOpacity`).
- Money display: profit/loss colour ONLY on net figures, always paired with +/− and a trend icon (accessibility). Individual deposit/withdraw amounts stay `onSurface`.
- Don't store arbitrary `IconData` for icon tree-shaking reasons — site avatars use the name's first letter.

## Android build quirks (important — these are deliberate)

This machine has AGP 9 / Gradle 9 and only preview-minor SDK 37 (`android-37.0`, no plain `android-37`). Three settings make builds work:

1. **`android/build.gradle.kts`** — a `subprojects { afterEvaluate { … compileSdkVersion(36) } }` block forces plugin modules (notably `flutter_secure_storage`, which declares compileSdk 37) to compile against the stable installed SDK 36. The 37 requirement is conservative; the plugins don't use 37 APIs. The "requires SDK 37" warning is expected and harmless.
2. **`android/gradle.properties`** — `kotlin.incremental=false` avoids a flaky "Could not close incremental caches …" Kotlin Build Tools API failure on Windows/Gradle 9.
3. **`android/app/src/main/kotlin/.../MainActivity.kt`** extends **`FlutterFragmentActivity`** (required by `local_auth`).

### Dependency pinning

- `flutter_secure_storage` is pinned to **^9.2.2** (not 11) — 11 hard-requires SDK 37. 9.x needs `win32 ^5`, which conflicts with `share_plus`/`package_info_plus` (`win32 ^6`) at resolution time, BUT that conflict is Windows-desktop only. If resolution breaks again, prefer a **`dependency_overrides: win32`** only if not building Windows — note that forcing win32 6 makes `flutter_secure_storage_windows` 3.x Dart fail to compile (the Flutter tool compiles all plugins' Dart even for Android), so 9.x + default win32 5 is the stable combo here.
- `file_selector` is used instead of `file_picker` (file_picker's win32 pin conflicted with `package_info_plus`).

## Manifest permissions

`INTERNET` (optional weekly FX refresh only) and `USE_BIOMETRIC` (app lock). App id: `io.github.kupperlupperdupper.betbook`.

## Release

See `docs/RELEASE.md`. Bump `pubspec.yaml` `version:` → push tag `vX.Y.Z` → GitHub Actions builds a signed APK + changelog + QR. Needs 4 secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.
