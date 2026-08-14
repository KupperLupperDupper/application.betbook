# BetBook — Design Handoff

Personal, offline ledger for deposits and withdrawals across betting sites.
Flutter · Material 3 · Android first (360 × 800 dp baseline) · Light + Dark · EN / DA.

**Non-negotiables:** calm over casino; money semantics are the loudest thing on screen; never colour alone; no celebration on gains, no drama on losses; nothing that nudges toward depositing.

---

## 1. Design language

A near-neutral cool-grey base with **one** brand accent — Slate Blue `#3B5F9E` — used only for navigation, actions and structure. It is deliberately desaturated so it never competes with money. All remaining saturation is reserved for profit/loss semantics.

Positive is **teal-leaning green**, negative **orange-leaning red**. They differ in hue (168° vs 24°) *and* in lightness (~12 L\*), which keeps them separable under deuteranopia and in greyscale. Every money figure additionally carries a `+` / `−` sign and a directional icon, so meaning never depends on hue.

Surfaces use flat tonal fills and M3 tonal elevation instead of shadows — cheap to raster on mid-range Android. The only shadow in the system is the FAB.

Signature interaction: the **card deck** (§6).

---

## 2. Tokens

### 2.1 ColorScheme — Light

| Role | Hex |
|---|---|
| primary | `#3B5F9E` |
| onPrimary | `#FFFFFF` |
| primaryContainer | `#D8E2FF` |
| onPrimaryContainer | `#001A41` |
| secondary | `#565E71` |
| onSecondary | `#FFFFFF` |
| secondaryContainer | `#DAE2F9` |
| onSecondaryContainer | `#131C2B` |
| tertiary | `#6F5675` |
| onTertiary | `#FFFFFF` |
| tertiaryContainer | `#F9D8FF` |
| onTertiaryContainer | `#281430` |
| error | `#BA1A1A` |
| onError | `#FFFFFF` |
| errorContainer | `#FFDAD6` |
| onErrorContainer | `#410002` |
| surface | `#FAF9FC` |
| onSurface | `#1A1B20` |
| surfaceVariant | `#E1E2EC` |
| onSurfaceVariant | `#44474F` |
| surfaceContainerLowest | `#FFFFFF` |
| surfaceContainerLow | `#F4F3F7` |
| surfaceContainer | `#EEEDF1` |
| surfaceContainerHigh | `#E9E7EC` |
| surfaceContainerHighest | `#E3E2E6` |
| outline | `#74777F` |
| outlineVariant | `#C4C6D0` |
| inverseSurface | `#2F3036` |
| inverseOnSurface | `#F1F0F4` |
| inversePrimary | `#ADC6FF` |
| scrim | `#000000` @ 32% |

### 2.2 ColorScheme — Dark

| Role | Hex |
|---|---|
| primary | `#ADC6FF` |
| onPrimary | `#0A305F` |
| primaryContainer | `#244777` |
| onPrimaryContainer | `#D8E2FF` |
| secondary | `#BEC6DC` |
| onSecondary | `#283141` |
| secondaryContainer | `#3E4759` |
| onSecondaryContainer | `#DAE2F9` |
| tertiary | `#DDBCE0` |
| onTertiary | `#3F2844` |
| tertiaryContainer | `#573E5C` |
| onTertiaryContainer | `#F9D8FF` |
| error | `#FFB4AB` |
| onError | `#690005` |
| errorContainer | `#93000A` |
| onErrorContainer | `#FFDAD6` |
| surface | `#121318` |
| onSurface | `#E3E2E6` |
| surfaceVariant | `#44474F` |
| onSurfaceVariant | `#C4C6D0` |
| surfaceContainerLowest | `#0D0E13` |
| surfaceContainerLow | `#1A1B20` |
| surfaceContainer | `#1E1F25` |
| surfaceContainerHigh | `#292A2F` |
| surfaceContainerHighest | `#34353A` |
| outline | `#8E9099` |
| outlineVariant | `#44474F` |
| inverseSurface | `#E3E2E6` |
| inverseOnSurface | `#2F3036` |
| inversePrimary | `#3B5F9E` |
| scrim | `#000000` @ 50% |

### 2.3 Semantic money tokens (`MoneyColors` ThemeExtension)

| Token | Light | Contrast (light) | Dark | Contrast (dark) |
|---|---|---|---|---|
| `color.profit` | `#0F6E52` | 5.42:1 on `surface` | `#6FD9B3` | 10.9:1 on `surface` |
| `color.onProfit` | `#FFFFFF` | 5.42:1 on profit | `#00382A` | 11.4:1 on profit |
| `color.profitContainer` | `#B8EBD8` | — | `#0B4B38` | — |
| `color.onProfitContainer` | `#002018` | 13.1:1 | `#B8EBD8` | 8.6:1 |
| `color.loss` | `#B3401A` | 5.11:1 on `surface` | `#FFB59A` | 9.6:1 on `surface` |
| `color.onLoss` | `#FFFFFF` | 5.11:1 on loss | `#5A1500` | 8.9:1 on loss |
| `color.lossContainer` | `#FFDBCF` | — | `#7A2A0E` | — |
| `color.onLossContainer` | `#3B0B00` | 12.4:1 | `#FFDBCF` | 7.9:1 |
| `color.neutral` (exact zero) | `#5A6068` | 6.24:1 | `#A9AEB6` | 8.1:1 |
| `color.neutralContainer` | `#E3E2E6` | — | `#34353A` | — |

All body-size usages meet WCAG AA 4.5:1; the hero figure exceeds AAA large-text.

**Rule:** profit/loss colour is applied **only to net figures** (overall P/L, per-site net, chart series, best/worst cards). Individual deposit and withdrawal amounts render in `onSurface` — they are neutral cash movements, not outcomes.

### 2.4 Chart categorical palette (`chart.cat.1…8`)

| # | Light | Dark |
|---|---|---|
| 1 | `#3B5F9E` | `#A8C4FF` |
| 2 | `#2E7D8F` | `#7FCBDC` |
| 3 | `#0F6E52` | `#6FD9B3` |
| 4 | `#4C6B2F` | `#A6CE7E` |
| 5 | `#8A6D1F` | `#DFC169` |
| 6 | `#B3401A` | `#FFB59A` |
| 7 | `#9A3B63` | `#F3A0C0` |
| 8 | `#6F5675` | `#DDBCE0` |

Legends pair each hue with a distinct marker shape (circle / square / triangle / diamond / plus / cross / star / hexagon) — never hue alone.

### 2.5 Typography

Family **Manrope** (`google_fonts`), fallback **Roboto** → platform default sans. Numerals: `FontFeature.tabularFigures()` on every money style. Axis labels use **JetBrains Mono** 11.

| Token / M3 role | Weight | Size (sp) | Line height | Letter-spacing |
|---|---|---|---|---|
| displayLarge | 800 | 57 | 64 | −0.25 |
| `type.display.pl` (hero P/L) | 800 | 57 | 60 | −1.0 · tabular |
| displayMedium | 700 | 45 | 52 | 0 |
| displaySmall | 700 | 36 | 44 | 0 |
| headlineLarge | 700 | 32 | 40 | 0 |
| headlineMedium | 700 | 28 | 36 | 0 |
| headlineSmall | 700 | 24 | 32 | 0 |
| titleLarge / `type.total.secondary` | 700 | 22 | 28 | 0 · tabular |
| titleMedium / `type.row.amount` | 600 / 700 | 16 | 24 | +0.15 · tabular on amounts |
| titleSmall | 600 | 14 | 20 | +0.1 |
| bodyLarge | 400 | 16 | 24 | +0.5 |
| bodyMedium | 400 | 14 | 20 | +0.25 |
| bodySmall | 400 | 12 | 16 | +0.4 |
| labelLarge | 600 | 14 | 20 | +0.1 |
| labelMedium | 600 | 12 | 16 | +0.5 |
| labelSmall | 600 | 11 | 16 | +0.5 |
| `type.chart.axis` | 500 | 11 | 14 | 0 · JetBrains Mono |

Money figure sizes in use: hero P/L 46–57 · site-detail hero 36 · amount input 52 · secondary totals 20–22 · list-row amount 16 · chart axis 11.

### 2.6 Spacing (`space.n`, 4 dp base)

`space.1` 4 · `space.2` 8 · `space.3` 12 · `space.4` 16 · `space.6` 24 · `space.8` 32 · `space.12` 48

`space.screenX` = 16 (24 at ≥ 400 dp width) · list-row min height 64 · section gap `space.6` · FAB inset 16 · bottom safe padding 24.

### 2.7 Radius (`radius.*`)

`deck` 28 · `card` 16 · `sheet` 28 (top corners) · `button` 20 (pill, full height) · `fab` 16 · `field` 12 · `chip` full · `avatar` 10.

### 2.8 Elevation

Tonal, not shadow:

| Level | Light | Dark |
|---|---|---|
| e0 page | `surface` | `surface` |
| e1 deck card | `surfaceContainerLow` | `surfaceContainerLow` |
| e2 inner card | `surfaceContainer` / `surfaceContainerLowest` + `outlineVariant` border | `surfaceContainer` + `outlineVariant` border |
| e3 FAB, sheet, dialog | `surfaceContainerHigh` / `primaryContainer` | `surfaceContainerHigh` / `primaryContainer` |

Only shadow in the system: FAB `0 2 4 rgba(0,0,0,.18)` in light; **removed entirely in dark**, replaced by tonal contrast. Modal scrim: `#000` 32% light / 50% dark.

### 2.9 Responsive

- **≤ 340 dp:** hero P/L steps down to 44 sp; segmented-control icons drop before labels.
- **360–400 dp:** baseline.
- **≥ 400 dp:** `space.screenX` → 24; deck peek → 18 dp.
- **Tablet / landscape (out of scope):** the deck degrades to a persistent `NavigationRail` with the suit glyphs as icons; cards become a two-pane list/detail. Do not fan cards above 600 dp width.

---

## 3. Component specs

### 3.1 App bars
- **Small** (detail routes): 56 dp, `surface`, title `titleLarge`, leading back `arrow_back`, up to 2 trailing actions. Elevates to `surfaceContainer` on scroll.
- **Large** (Site detail alternative): 152 dp collapsing to 56.
- Deck section cards use **no app bar** — the section label (`labelSmall` uppercase, `onSurfaceVariant`) sits inside the card at 22 dp top padding.

### 3.2 Card-deck navigation → §6

### 3.3 FAB ("Add transaction")
56 × 56, `radius.fab`, `primaryContainer` / `onPrimaryContainer`, icon `add` 26. Extended variant on Sites ("Tilføj" / "Add site").
States: default · pressed (12% state layer, scale 0.97, 80 ms) · focused (3 dp `onPrimaryContainer` outline offset 2) · disabled (n/a — the FAB is never disabled).
Position: bottom-right inset 16, lifted to 64 above the deck indicator on deck cards.

### 3.4 Cards
- **Hero P/L**: `surfaceContainerHigh`, `radius.card`, padding 18. Trend icon 22–26 + figure `type.display.pl` + one plain supporting line.
- **Site summary / stat card**: `surfaceContainerLowest` (light) / `surfaceContainer` (dark) + 1 dp `outlineVariant`, `radius.card`, padding 14.
- **Best / worst**: `profitContainer` / `lossContainer` fills with their on-colours.

### 3.5 List items
- **Site row** — min height 64: avatar 36 (`radius.avatar`, site colour, white initial or preset icon) · name `titleMedium` · subtitle count `bodySmall onSurfaceVariant` · currency badge chip · net figure `type.row.amount` in profit/loss/neutral with arrow glyph.
- **Transaction row** — min height 64: circular 36 icon on `lossContainer` (deposit, `arrow_downward`) or `profitContainer` (withdrawal, `arrow_upward`) · type label · date/time + optional note `bodySmall` · amount `type.row.amount` in `onSurface`, running net below in `bodySmall onSurfaceVariant`.
- States: pressed = 12% `onSurface` state layer across the full row; focused = 3 dp `primary` outline inset; long-press opens edit/delete menu.

### 3.6 Buttons
Height 44 (tap target 48), `radius.button`, label `labelLarge`.

| Variant | Container | Label |
|---|---|---|
| Filled | `primary` | `onPrimary` |
| Tonal | `primaryContainer` | `onPrimaryContainer` |
| Outlined | transparent + 1 dp `outline` | `primary` |
| Text | transparent | `primary` |

States: hover 8% · focus 10% + 3 dp outline offset 2 · pressed 12% · disabled `onSurface` 12% container / `onSurface` 38% label. Destructive actions are **text or outlined in `error`** — never a filled red button.

### 3.7 Segmented type toggle (Deposit ↔ Withdrawal)
Height 44 (48 in the transaction form), pill, 1 dp `outline`. Selected segment: `primaryContainer` / `onPrimaryContainer` weight 700 with a leading direction icon. Unselected: transparent / `onSurfaceVariant` weight 600. Labels never truncate — at ≤ 340 dp the icons drop first. Announced to TalkBack as a radio group.

### 3.8 Chips
Height 32 (tap target 48 via padding), full radius. Filter chip selected = `primaryContainer`; unselected = 1 dp `outline` + `onSurfaceVariant`; disabled = 1 dp `outlineVariant` + 38% label. Currency badge = static `surfaceVariant` / `onSurfaceVariant`, `labelSmall` 700. **Chip rows wrap, never scroll-truncate** — "Brugerdefineret" is ~40% wider than "Custom".

### 3.9 Inputs
Outlined only, 56 dp tall, `radius.field`.

| State | Border | Label |
|---|---|---|
| default | 1 dp `outline` | `onSurfaceVariant` |
| focused | 2 dp `primary` | `primary` 700 |
| error | 2 dp `error` + helper text | `error` |
| disabled | 1 dp `outlineVariant`, fill `surfaceContainerLow` | 38% |

- **Amount field**: 52 sp display numeral, centred, tabular, locale decimal separator (`,` in DA), with a 2 dp `primary` underline; backed by a custom 4×3 keypad on `surfaceContainer` so the OS keyboard never covers the Save button.
- **Currency picker**: modal list, code + full name, search above 8 entries.
- **Colour picker**: 8 preset swatches from `chart.cat`, 36 dp circles, selected = 3 dp `primary` outline offset 2.
- **Icon picker**: 44 dp outlined tiles, selected = 2 dp `primary`.
- **Date/time**: standard M3 date picker + time picker; defaults to now.

### 3.10 Charts (lightweight — `CustomPainter`, no gradients)
- **Line / sparkline**: 2.5 dp stroke in `color.profit` or `color.loss` depending on the *end* value, round caps/joins, terminal dot r 3.5. Zero baseline = 1 dp `outlineVariant` dashed `3 4`. Max 2 horizontal gridlines. No fill, no shadow, no area gradient.
- **Bar breakdown**: 12 dp track `surfaceContainerHighest`, radius 6; negative bars grow **right-to-left**, positive left-to-right from the same zero axis; value label right-aligned, tabular, in the money colour.
- **Monthly summary**: single-line text run or 12 dp bars, same rules.
- Axis labels `type.chart.axis`, `outline`. Touch: tap a point → tooltip on `inverseSurface` with date + value; no crosshair animation.

### 3.11 Sheets & dialogs
- **Bottom sheet** (quick add/edit): `surfaceContainerHigh`, `radius.sheet` top, 4 × 32 drag handle in `outlineVariant`, scrim 32% / 50%.
- **Confirmation dialog** (destructive): `surfaceContainer`, radius 28, title `headlineSmall`, body `bodyMedium`, actions right-aligned — "Annullér" text/`primary`, "Slet" text/`error`. Copy states the exact consequence ("12 transaktioner bliver slettet permanent").
- **Clear all data**: same dialog plus a typed confirmation field.
- **Snackbar**: `inverseSurface` / `inverseOnSurface`, radius 8, single action in `inversePrimary`, 4 s, always offers UNDO for destructive or save actions.

### 3.12 Empty states
Suit-glyph mark (2 × 2 ♠♥♦♣ in `surfaceVariant`, 56–64 dp) + `headlineSmall`/`titleLarge` line + one supportive `bodyLarge` sentence + one filled primary action.

| Screen | Headline | Support | Action |
|---|---|---|---|
| Dashboard | Nothing tracked yet | Add your first deposit or withdrawal and BetBook will show you, honestly, where you stand. | Add transaction |
| Sites | Ingen spillesteder endnu | Tilføj det første sted, du spiller på, så kan du følge dine ind- og udbetalinger. | Tilføj spillested |
| Site detail | No transactions here yet | This site is set up. Add the first deposit or withdrawal to start the ledger. | Add transaction |
| Stats | Not enough data yet | Stats appear once you have transactions in more than one month. | Add transaction |

### 3.13 Micro-interactions
- Hero P/L **count-up** 400 ms `easeOutCubic`, once per screen entry, only when the value changed.
- **Zero crossing**: colour and sign cross-fade 250 ms, arrow rotates through the flat state. No bounce, no flash.
- Press states 80 ms in / 120 ms out.
- Haptics: `selectionClick` on deck settle, toggle change, keypad tap. Nothing else.
- **Forbidden**: confetti, coins, streak counters, sounds, celebratory or sympathetic animation of any kind.

---

## 4. Iconography

Material Symbols Rounded, weight 400, optical size 24, fill 0, stroke-consistent at 22–26 dp.

| Purpose | Icon |
|---|---|
| Deposit | `arrow_downward` |
| Withdrawal | `arrow_upward` |
| Profit | `trending_up` |
| Loss | `trending_down` |
| Break-even | `trending_flat` |
| Site presets | `sports_soccer`, `stadium`, `style`, `public`, `storefront`, `casino_off`, `circle`, `change_history` |
| Settings — general | `language`, `palette`, `currency_exchange` |
| Security | `lock`, `fingerprint` |
| Data | `backup`, `download`, `upload`, `delete_forever` |
| Responsible gambling | `shield_moon`, `notifications_active` |
| Empty states | brand suit mark, `query_stats`, `inbox` |

App mark: 2 × 2 grid of ♠ ♥ ♦ ♣ in `onPrimary` on a `primary` squircle, `radius.card`, 7 dp padding — flat, monochrome, no face-card art.

---

## 5. Screens

Deck sections: **Dashboard ♠ · Sites ♥ · Stats ♦ · Settings ♣**.
Pushed routes (standard Material push / modal, **not** deck cards): Add/edit transaction, Site detail, Add/edit site, Onboarding, App lock.

### 5.1 Onboarding (4 swipeable steps)
Elements: brand mark · `headlineMedium` title · `bodyLarge` support · step content · page dots (active = 22 × 8 pill `primary`) · "Skip" text button + filled "Continue".
Steps: (1) welcome + value prop + "All data stays on your device"; (2) language EN / DA; (3) theme System / Light / Dark with a live mini-preview of the Dashboard card; (4) base currency, default **DKK**.
Tokens: `surface`, `primaryContainer` for the selected option, `radius.card` option tiles, `space.6` rhythm.
States: nothing selected → Continue uses the default and stays enabled; back-swipe allowed on every step.

### 5.2 Dashboard (deck ♠)
Elements: section label · hero P/L (`type.display.pl` + trend icon + sign) · one plain supporting line ("You're down overall. Last 30 days: −1.240 kr") · Deposited / Withdrawn cards · profit-over-time sparkline card · site summary list (top 3–4 + "See all") · FAB · deck indicator.
Empty state: §3.12 plus the on-device privacy line.
Error: if a site's currency has no rate, its row shows a `warning` glyph and the hero excludes it with a "1 site not converted" note.

### 5.3 Sites (deck ♥)
Elements: count + combined net header · sort chips (Net / Name / Activity) · site rows · extended FAB "Add site" · indicator.
Empty: §3.12. Rows with net exactly 0 use `color.neutral` and `trending_flat`.

### 5.4 Site detail (pushed)
App bar with back, edit (`edit`), delete (`delete` in `error`). Hero net + Deposited / Withdrawn / Currency triplet on `surfaceContainerHigh`. Month-grouped transaction list with a running net per row. FAB adds a transaction pre-filled with this site.
Delete → confirmation dialog (§3.11). Empty → §3.12.

### 5.5 Add / edit transaction (pushed, full-screen)
Close (`close`) + title ("Ny transaktion" / "Redigér transaktion"). Type toggle · large amount field · site selector row with avatar (menu includes **"+ Create new site"**) · date/time row defaulting to now · optional note. Custom keypad + full-width "Gem transaktion".
Edit variant: identical, pre-filled, title changes, and a `delete` action appears in the app bar.
Errors: amount = 0 or empty → error field + "Beløbet skal være større end 0"; no site chosen → site row turns error. Save stays disabled until both are valid.

### 5.6 Add / edit site (pushed)
Live preview of the resulting site row pinned at the top, updating as fields change. Name (required, duplicate name warns but is allowed) · currency picker · 8-swatch colour picker · icon picker · Cancel / Save.

### 5.7 Stats (deck ♦)
Date-range chips 1M / 3M / 6M / 1Y / All / Custom · profit-over-time line · per-site bar breakdown · best / worst site cards · monthly summary line · indicator.
Not-enough-data: chart area replaced by §3.12 Stats empty state; chips stay visible.

### 5.8 Settings (deck ♣)
Grouped, section headers in `primary` `labelMedium` uppercase.
- **General** — language (EN/DA), theme (system/light/dark), base currency.
- **Exchange rates** — editable table currency → base, tabular 4-decimal values, "Edited by you · 2 Aug 2026", offline-only note. Tapping a row opens an inline numeric field.
- **Security** — app lock switch, biometric switch (disabled with an explanatory line when no hardware), change PIN.
- **Data** — export JSON / CSV, import, **Clear all data** in `error`.
- **Playing responsibly** — `secondaryContainer` card offering a monthly deposit limit and a net-loss alert. Copy is supportive and states plainly that there are no streaks or rewards.
- **About** — version + build (e.g. `1.0.0 (128)`), licenses, "All data stays on your device."

### 5.9 App lock (pushed, root)
Brand mark · "BetBook er låst" · instruction line · biometric affordance 76 dp on `primaryContainer` · 4-dot PIN indicator · 3 × 4 keypad with a "Biometri" shortcut and backspace.
States: idle (dots `outline`) · entering (filled `primary`) · **wrong PIN** (dots `error`, 300 ms 8 dp shake, `errorContainer` banner "Forkert pinkode. 2 forsøg tilbage.") · locked out after 5 attempts (60 s countdown, calm wording, no alarm colour beyond `error`) · biometric unavailable → PIN only.

---

## 6. Card-deck navigation spec

**Structure.** A horizontal `PageView` of 4 section cards, `viewportFraction 0.92`, `clipBehavior: none`. Each card is a full-bleed `Container`: margin `6 top / 12 bottom`, `radius.deck 28`, fill `surfaceContainerLow`, 1 dp border `outlineVariant` (light) / `surfaceVariant` (dark). A corner pip — the section's suit glyph, 14 sp, `outlineVariant` (light) / `outline` (dark) — sits at top 14 / right 18. The card owns all of that section's content and its own scroll.

**Peek.** Neighbours show a 14 dp sliver at each screen edge: `surfaceContainerHigh` fill, 1 dp `outlineVariant`, rounded 20 on the inner side only, vertically inset 14 top / 26 bottom so the stack reads as layered paper. At ≥ 400 dp width the sliver grows to 18 dp.

**Transition.** Scale interpolates linearly against page offset: active `1.0` → neighbour `0.94`; opacity `1.0` → `0.86`. Card content translates at `0.15×` the page delta (parallax). During the drag the outgoing card slides left and shrinks while the incoming card grows toward full size — the mid-swipe mockups show `out: scale .93 / in: scale .99` at drag 0.62.

**Physics.** `SpringDescription(mass: 1, stiffness: 220, damping: 26)` — one soft settle, no wobble. Fling threshold 350 px/s; below it the page snaps back. `HapticFeedback.selectionClick()` fires on settle only, never during drag.

**Indicator.** Centred row of ♠ ♥ ♦ ♣, 15 sp `outline`, active 17 sp `primary`, cross-fading with page offset; 18 dp gap, each with a 48 dp tap target that jumps to its section. Sits inside the active card at bottom 16.

**Dark theme.** No shadows at all: depth comes from the `surfaceContainerHigh #292A2F` peek strip against `surfaceContainerLow #1A1B20` card and `#121318` page, plus the `#44474F` hairline. Card edges stay clearly readable at minimum screen brightness.

**Semantics.** The `PageView` exposes each card as `Semantics(label: "Sites, section 2 of 4")`. Left/right swipe is mirrored for RTL (not currently shipped). Detail routes push over the deck with the standard Material shared-axis-Z transition and restore the deck at the same page on pop.

---

## 7. Accessibility

- **Contrast:** every colour pair above meets WCAG AA 4.5:1 for body text; hero figures and container pairs exceed 7:1. `outlineVariant` is decorative only and never carries meaning alone.
- **Never colour alone:** every money figure = sign (`+` / `−`) + directional icon + colour. Chart series carry marker shapes. Selected states carry a checkmark or an outline, not just a fill.
- **Tap targets:** minimum 48 × 48 dp everywhere, including chips (32 visual + padding), indicator glyphs and table rows.
- **Text scaling:** layouts tested to `textScaleFactor 1.3`. The hero P/L clamps at 1.15 and then wraps rather than truncating; list rows grow from 64 dp; chip rows wrap to additional lines; no fixed-height text container in the system.
- **Localisation:** all labels sized for Danish (+15–35% length). No label is width-constrained; icons drop before text. Numbers, dates and the decimal separator follow the locale (`1.234,56 kr` in DA).
- **Motion:** honours `MediaQuery.disableAnimations` — deck transitions become instant page changes, count-up is skipped.
- **Screen reader:** money figures are announced as "minus 4.310 kroner, down" so direction is spoken, not implied.

---

## 8. Flutter transcription notes

```dart
// Money colours as a ThemeExtension
@immutable
class MoneyColors extends ThemeExtension<MoneyColors> {
  final Color profit, onProfit, profitContainer, onProfitContainer;
  final Color loss, onLoss, lossContainer, onLossContainer;
  final Color neutral, neutralContainer;
  // light:  profit #0F6E52 / onProfit #FFFFFF / profitContainer #B8EBD8 / onProfitContainer #002018
  //         loss   #B3401A / onLoss   #FFFFFF / lossContainer   #FFDBCF / onLossContainer   #3B0B00
  //         neutral #5A6068 / neutralContainer #E3E2E6
  // dark:   profit #6FD9B3 / onProfit #00382A / profitContainer #0B4B38 / onProfitContainer #B8EBD8
  //         loss   #FFB59A / onLoss   #5A1500 / lossContainer   #7A2A0E / onLossContainer   #FFDBCF
  //         neutral #A9AEB6 / neutralContainer #34353A
}
```

- Build `ColorScheme` explicitly from §2.1 / §2.2 — do **not** regenerate from a seed; the greys are hand-tuned.
- `TextTheme` from §2.5 via `GoogleFonts.manropeTextTheme()`, then override each role's weight/size/height/spacing.
- Money styles: `.copyWith(fontFeatures: const [FontFeature.tabularFigures()])`.
- `useMaterial3: true`; set `shadowColor: Colors.transparent` in the dark theme.
