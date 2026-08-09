# BetBook — Design → Flutter Handoff

> The bridge between the design returned by Claude (see `CLAUDE_DESIGN_PROMPT.md`) and the Flutter implementation. It tells the **designer** exactly what to hand back, and tells the **developer** exactly how to wire those tokens into Material 3 `ThemeData`. Target: Flutter (Dart SDK `^3.12.2`), Material 3, Android-first, offline.

---

## 1. Design token → Flutter mapping

Flutter's Material 3 theme is driven by a `ColorScheme`, a `TextTheme`, and shape/elevation settings on `ThemeData`. Money semantics (profit/loss) have **no native slot** and go into a `ThemeExtension` (see §3). Build the theme by hand from explicit hex tokens — do **not** rely solely on `ColorScheme.fromSeed`, because the hero P/L colors and exact brand hues must be pinned.

### 1.1 Colors → `ColorScheme`

| Design token | Flutter `ColorScheme` field | Notes |
|---|---|---|
| `color.primary` | `primary` | Brand accent. Also feeds FAB/filled buttons. |
| `color.onPrimary` | `onPrimary` | Text/icon on `primary`. |
| `color.primaryContainer` | `primaryContainer` | Tonal button / selected chip backgrounds. |
| `color.onPrimaryContainer` | `onPrimaryContainer` | |
| `color.secondary` (+ container/on) | `secondary`, `secondaryContainer`, `onSecondary…` | Secondary emphasis, filter chips. |
| `color.tertiary` (+ container/on) | `tertiary`, `tertiaryContainer`, `onTertiary…` | Accent for charts/highlights. |
| `color.surface` | `surface` | Base screen background (M3 merged `background`). |
| `color.surfaceContainerLowest/Low/High/Highest` | `surfaceContainerLowest` … `surfaceContainerHighest` | Card / sheet / app-bar layering (M3 tonal elevation). |
| `color.surfaceVariant` | `surfaceVariant` | Subtle fills, divider zones. |
| `color.outline` / `color.outlineVariant` | `outline` / `outlineVariant` | Borders, dividers. |
| `color.onSurface` / `color.onSurfaceVariant` | `onSurface` / `onSurfaceVariant` | Primary / secondary text. |
| `color.error` (+ container/on) | `error`, `errorContainer`, `onError…` | Validation & destructive actions. **Distinct from `color.loss`** — an invalid form field is not the same as a losing balance. |
| `color.inverseSurface` / `onInverseSurface` / `inversePrimary` | `inverseSurface` … | Snackbars. |
| `brightness` | `brightness` | `light` / `dark` per theme. |

Build one `ColorScheme(brightness: Brightness.light, …)` and one `Brightness.dark`, each from the designer's hex list.

### 1.2 Typography → `TextTheme`

| Design token (M3 role) | Flutter `TextTheme` getter |
|---|---|
| `type.displayLarge/Medium/Small` | `displayLarge` / `displayMedium` / `displaySmall` |
| `type.headlineLarge/Medium/Small` | `headlineLarge` / `headlineMedium` / `headlineSmall` |
| `type.titleLarge/Medium/Small` | `titleLarge` / `titleMedium` / `titleSmall` |
| `type.bodyLarge/Medium/Small` | `bodyLarge` / `bodyMedium` / `bodySmall` |
| `type.labelLarge/Medium/Small` | `labelLarge` / `labelMedium` / `labelSmall` |

- Wire the family via **`google_fonts`** (e.g. `GoogleFonts.interTextTheme(...)`) or bundle the TTFs under `pubspec.yaml > flutter > fonts` and set `fontFamily`. Keep an explicit fallback to the platform default.
- **Money figures use tabular figures.** Apply `fontFeatures: [FontFeature.tabularFigures()]` (and `FontFeature.slashedZero()` if the family supports it) to the hero P/L style, list-row amounts, and chart axis labels so digits align and totals don't shift.

### 1.3 Shape, elevation, components

| Design token | Flutter target |
|---|---|
| `radius.card` / `sheet` / `button` / `chip` / `field` | `CardTheme.shape`, `BottomSheetThemeData.shape`, `ButtonStyle.shape`, `ChipThemeData.shape`, `InputDecorationTheme.border` — each `RoundedRectangleBorder(borderRadius: …)`. |
| `space.*` (4/8/12/16/24/32/48) | A `const` spacing class (e.g. `Insets.md = 16`); use for padding/gaps. Flutter has no theme slot for spacing — centralize in one Dart file. |
| `elevation.*` / tonal surface | Prefer M3 **tonal elevation** (`surfaceContainer*` roles) over `Card`/`Material` shadow `elevation`. Set `ThemeData.useMaterial3: true`. |
| Component tokens (FAB, card-deck nav, app bar, list rows) | Corresponding `*ThemeData` on `ThemeData`: `floatingActionButtonTheme`, `appBarTheme`, `listTileTheme`, `segmentedButtonTheme`, `chipTheme`, `snackBarTheme`, `dialogTheme`, `bottomSheetTheme`. The card-deck nav (see §1.4) is a custom `PageView`, not a themed Material component, but its card frame/radius/edge should read from `radius.card` and the surface tokens. |

Assemble as `ThemeData(useMaterial3: true, colorScheme: …, textTheme: …, extensions: [BetBookColors…], …)` and provide both `theme:` and `darkTheme:` to `MaterialApp`, with `themeMode` driven by the user's system/light/dark choice.

### 1.4 Card-deck navigation (signature interaction)

Top-level sections (Dashboard, Sites, Stats, Settings, …) are a **horizontally swipeable deck of full-bleed cards** — the app's hero interaction. Map it to Flutter as follows:

- **`PageView` with `viewportFraction < 1.0`** (e.g. `PageController(viewportFraction: 0.88–0.92)`) so the **edges of the adjacent cards peek** on both sides, matching the design's peek affordance. Wrap each page's child in horizontal padding so cards read as separated in the deck.
- Alternatively a **`CardSwiper`-style** package (e.g. `flutter_card_swiper`) if the design calls for a more literal stacked/fanned deck; the `PageView` route is lighter and usually sufficient for a peek-and-slide deck. Pick one and keep it consistent.
- **Scale / parallax between active and peeking cards:** use `AnimatedBuilder` listening to the `PageController` `page` value to interpolate a subtle scale (and optional translate) on neighbors — the active card at full size, neighbors slightly smaller — per the design's transition mockup.
- **Spring physics:** the default `PageView` physics gives the settle; if a springier feel is specified, supply a custom `ScrollPhysics` / `PageScrollPhysics` or drive settle animations with a `SpringSimulation`. Respect reduced-motion.
- **Active-section indicator:** a lightweight custom row of dots or the card-suit / mini-card motif from the design, driven by the same `page` value. Not a Material component — build it small and `const` where possible.
- **Scope:** only top-level sections are pages in this `PageView`. **Add/edit transaction, Site detail, Add/edit site, Onboarding, and App-lock are pushed routes** (`Navigator.push` / modal routes) on top of the deck, using standard Material transitions.

**Performance considerations (Android-first):**
- Rely on `PageView`'s **lazy building** — use `PageView.builder` (not the eager `PageView(children: […])`) so only the visible/adjacent section cards build.
- Keep each card's static chrome (frame, indicator, backgrounds) as **`const` widgets** so rebuilds during the swipe animation stay cheap; isolate the animating parts under the `AnimatedBuilder` so the whole card subtree doesn't rebuild each frame.
- Avoid expensive per-frame work in the peek/scale transform (no blurs/shadows recomputed per frame; prefer `Transform.scale` + tonal surfaces over `BackdropFilter`).
- Keep each section's heavy content (charts, long lists) in its own widget with its own state so swiping doesn't rebuild sibling sections; consider `AutomaticKeepAliveClientMixin` only where rebuilds are genuinely costly, and measure before adding it.

---

## 2. What the designer must return (handoff checklist)

A design is "handoff-complete" only when all of the following are provided:

- [ ] **Both themes.** Every token and every screen in **light and dark**.
- [ ] **Hex values, not swatches.** Full `ColorScheme` for both themes as `#RRGGBB` (or `#AARRGGBB`) — every role in the §1.1 table.
- [ ] **Semantic money tokens** in hex, both themes: `profit`, `loss`, `neutral`, plus `*Container` / `on*` variants, with the contrast ratio each achieves against its background.
- [ ] **Categorical chart palette** (6–8 hues) in hex.
- [ ] **Typography:** family name (Google-Fonts-available) + fallback, and for each role: weight, size (sp/logical px), line height, letter-spacing. Note which styles use tabular figures.
- [ ] **Spacing scale** (named steps) and **corner-radius** tokens (named) and **elevation/tonal** scheme.
- [ ] **Component states:** default, pressed/hover, focused, disabled, error — at minimum for buttons, the Deposit/Withdrawal toggle, inputs, chips, list rows, and the FAB.
- [ ] **Empty states** for dashboard, sites, transactions, and stats (art + copy + primary action).
- [ ] **Danish proof:** at least a few screens shown with Danish copy demonstrating longer strings still fit.
- [ ] **A compact token sheet** (single table/list) a dev can transcribe directly into `ColorScheme` + `TextTheme` + the `ThemeExtension`.
- [ ] **Icon list:** the specific Material Symbols (or provided SVGs) for deposit, withdrawal, profit-up, loss-down, settings sections, backup, lock, and empty states.
- [ ] **App-mark & icon** source (see §6).

---

## 3. Semantic money colors as a `ThemeExtension`

Material 3's `ColorScheme` has no profit/loss role. Reusing `primary`/`error` for money would break the moment the brand hue or an error state changes, and would fight colorblind requirements. Model money semantics as a first-class **`ThemeExtension<BetBookColors>`** so both themes carry their own values and widgets read them via `Theme.of(context)`.

```dart
import 'package:flutter/material.dart';

@immutable
class BetBookColors extends ThemeExtension<BetBookColors> {
  const BetBookColors({
    required this.profit,
    required this.onProfit,
    required this.profitContainer,
    required this.onProfitContainer,
    required this.loss,
    required this.onLoss,
    required this.lossContainer,
    required this.onLossContainer,
    required this.neutral,        // exactly break-even / zero
    required this.chartSeries,    // categorical palette for per-site charts
  });

  final Color profit;
  final Color onProfit;
  final Color profitContainer;
  final Color onProfitContainer;
  final Color loss;
  final Color onLoss;
  final Color lossContainer;
  final Color onLossContainer;
  final Color neutral;
  final List<Color> chartSeries;

  /// Pick the right money color for a signed amount.
  Color forAmount(num value) =>
      value > 0 ? profit : (value < 0 ? loss : neutral);

  @override
  BetBookColors copyWith({
    Color? profit,
    Color? onProfit,
    Color? profitContainer,
    Color? onProfitContainer,
    Color? loss,
    Color? onLoss,
    Color? lossContainer,
    Color? onLossContainer,
    Color? neutral,
    List<Color>? chartSeries,
  }) {
    return BetBookColors(
      profit: profit ?? this.profit,
      onProfit: onProfit ?? this.onProfit,
      profitContainer: profitContainer ?? this.profitContainer,
      onProfitContainer: onProfitContainer ?? this.onProfitContainer,
      loss: loss ?? this.loss,
      onLoss: onLoss ?? this.onLoss,
      lossContainer: lossContainer ?? this.lossContainer,
      onLossContainer: onLossContainer ?? this.onLossContainer,
      neutral: neutral ?? this.neutral,
      chartSeries: chartSeries ?? this.chartSeries,
    );
  }

  @override
  BetBookColors lerp(ThemeExtension<BetBookColors>? other, double t) {
    if (other is! BetBookColors) return this;
    return BetBookColors(
      profit: Color.lerp(profit, other.profit, t)!,
      onProfit: Color.lerp(onProfit, other.onProfit, t)!,
      profitContainer: Color.lerp(profitContainer, other.profitContainer, t)!,
      onProfitContainer:
          Color.lerp(onProfitContainer, other.onProfitContainer, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      onLoss: Color.lerp(onLoss, other.onLoss, t)!,
      lossContainer: Color.lerp(lossContainer, other.lossContainer, t)!,
      onLossContainer: Color.lerp(onLossContainer, other.onLossContainer, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      chartSeries: t < 0.5 ? chartSeries : other.chartSeries,
    );
  }
}
```

Register one instance per theme (values from the designer's hex sheet):

```dart
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: betbookLightScheme,
  textTheme: betbookTextTheme,
  extensions: const [betbookColorsLight],
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: betbookDarkScheme,
  textTheme: betbookTextTheme,
  extensions: const [betbookColorsDark],
);
```

Read at the widget level — automatically correct for the active theme, and animates on theme switch via `lerp`:

```dart
final money = Theme.of(context).extension<BetBookColors>()!;
Text('${value >= 0 ? '+' : '−'}$formatted',
    style: TextStyle(color: money.forAmount(value)));
```

> The transition of the smooth sign/color change as a total crosses zero (from the design's micro-interactions) is handled for free by `lerp` when the theme changes, and by an `AnimatedDefaultTextStyle` / implicit color animation when the *value* changes.

---

## 4. Localization — never hardcode strings

- **All user-facing copy goes through ARB files** (`lib/l10n/app_en.arb`, `lib/l10n/app_da.arb`) via Flutter's `gen_l10n` (`flutter_localizations` + `intl`; set `generate: true` under `flutter:` in `pubspec.yaml` and add an `l10n.yaml`). No string literals in widgets.
- **English + Danish** only. Language is chosen at first launch and stored locally; wire it to `MaterialApp.locale` with `supportedLocales: [Locale('en'), Locale('da')]` and a system-locale default when the user hasn't chosen.
- **Danish is longer.** Design and build for text that wraps; avoid fixed-width labels and single-line assumptions on buttons, chips, nav labels, and list rows. Use `Flexible`/`Expanded` and allow `softWrap`.
- **Numbers, currency, and dates are localized too.** Use `intl`'s `NumberFormat.currency` / `DateFormat` with the active locale (Danish uses `.` as thousands sep and `,` as decimal, and typically `kr` / `1.234,56`). The base-currency total and every amount must format per locale — don't concatenate strings by hand.
- Provide keys with placeholders (e.g. `netThisMonth(amount)`), not pre-composed sentences, so both languages read naturally.

---

## 5. Accessibility (WCAG AA baseline)

- **Contrast:** body text and money figures meet **AA 4.5:1** against their background; large text (≥ 24 px / 18.66 px bold) meets **3:1**. The designer must state the ratio for `profit`/`loss`/`neutral` on their surfaces. Verify in both themes.
- **Never rely on color alone.** Profit/loss must **also** carry a **`+` / `−` sign and a directional icon** (trend-up / trend-down), so the state is unambiguous in grayscale and for red-green color-vision deficiency. This is a hard requirement, not a nice-to-have.
- **Tap targets:** minimum **48 × 48 dp** for every interactive element (Material's `kMinInteractiveDimension`); ensure the Deposit/Withdrawal toggle, chips, icon buttons, and list-row actions comply.
- **Dynamic text scaling:** honor the OS text-size setting via `MediaQuery.textScaler`. Layouts must survive large scale factors (test at ~1.3–2.0×) without clipping the hero figure or truncating totals; prefer wrapping and scrollable content over fixed heights.
- **Semantics:** label icons and icon-only buttons with `Semantics` / `tooltip`; announce money values with their sign in a screen-reader-friendly form (e.g. "minus 1.240 kroner"), not just a colored glyph.
- **Motion:** keep micro-interactions subtle and respect reduced-motion (`MediaQuery.disableAnimations`) — no essential meaning conveyed by animation alone.
- **App-lock screen** must be fully operable by keyboard/switch/screen reader; PIN entry needs accessible labels and clear error text (not color-only).

---

## 6. Asset guidance

| Asset | Format | Sizes / specs | Notes |
|---|---|---|---|
| **App icon (master)** | Vector (SVG/AI) → export PNG | 1024 × 1024 master, no rounded corners baked in | Calm ledger/chart-line mark, not casino imagery. Provide on-brand background. |
| **Android adaptive icon** | PNG (or vector drawable) | **foreground + background** layers, each **432 × 432** within a 108dp safe zone (keep key art within the central ~66dp / ~264px) | Wire via `flutter_launcher_icons` (`adaptive_icon_foreground`/`_background`). Monochrome layer for Android 13+ themed icons is a plus. |
| **iOS app icon** | PNG, no alpha | 1024 × 1024 (Xcode generates the rest) | Square, no transparency, no pre-rounded corners. |
| **Splash / launch screen** | PNG (1×/2×/3×) + color | Centered logo on a solid brand surface, light + dark variants | Wire via `flutter_native_splash`; keep it minimal — logo + background only. Provide both light and dark background hex. |
| **In-app site icons** | Material Symbols + a small preset set (SVG) | 24dp base | For the site color/icon picker. Ship as a curated preset library, tinted by the site's chosen color. |
| **Empty-state art** | SVG (theme-tintable) or dual PNG | fits ~200–280dp wide | Must read in both themes; prefer line art tintable via `currentColor`/theme color. |

Deliver source (vector) plus exported rasters, and name files by role. Generate launcher/splash via `flutter_launcher_icons` and `flutter_native_splash` from the masters rather than hand-placing per-density PNGs.

---

## 7. Definition of Done — design phase

The design phase is complete when:

1. **Every screen** in `CLAUDE_DESIGN_PROMPT.md` (onboarding, dashboard, sites list, site detail, add/edit transaction, add/edit site, stats, settings, app lock) exists in **light and dark**, including empty and key error states — **and the card-deck navigation** is delivered as both a resting/peek state and a mid-swipe transition state (frame, edge/peek, active-section indicator) in both themes.
2. A **complete token sheet** is delivered: full light + dark `ColorScheme` in hex, semantic money tokens (+containers, +on-colors, with contrast ratios), categorical chart palette, typography scale (family + fallback + per-role specs + tabular-figure note), and spacing / radius / elevation scales — all named.
3. **Component specs** cover all states (default/pressed/focused/disabled/error) for buttons, the Deposit/Withdrawal toggle, inputs, chips, list rows, cards, FAB, nav bar, app bars, sheets, dialogs, snackbars, and charts.
4. **Accessibility is verified:** AA contrast confirmed for text and money colors in both themes; profit/loss never color-only (sign + icon present); tap targets ≥ 48dp; layouts proven at large text scale; Danish copy shown fitting on key screens.
5. **Assets** (app icon master, Android adaptive layers, iOS icon, splash light/dark, empty-state art, site-icon preset set) are delivered in the specified formats/sizes.
6. The token sheet maps **1:1** onto the tables in §1 with no gaps — a developer can implement the theme and the `BetBookColors` extension without asking follow-up questions.
7. **Responsible-design guardrails hold:** nothing glamorizes gambling; gains are calm, losses are honest and non-shaming; responsible-gambling tools are easy and supportive.

---

### Appendix — suggested Flutter packages (for the dev, not the designer)

`google_fonts` (typography), `flutter_localizations` + `intl` (i18n/formatting), `fl_chart` (line/bar/sparkline), `local_auth` (biometric app lock), `flutter_secure_storage` (PIN/secrets), `flutter_launcher_icons` + `flutter_native_splash` (icons/splash). For the card-deck navigation, a plain **`PageView.builder`** (framework, no dependency) is preferred; **`flutter_card_swiper`** is an option only if a literal stacked/fanned deck is required. These are recommendations to keep the design decisions implementable; final choices belong to the implementation phase.
