# BetBook — UI Design Generation Prompt

> **How to use this file:** Copy everything below the horizontal rule into Claude (the design tool) as a single prompt. It is written to be self-contained. It asks for a complete, coherent design system plus mockups for every screen, in both light and dark, ready to hand to a Flutter developer. If your design tool has a length limit, you may paste it in two halves at the marked split point — but a single paste is preferred.

---

## ROLE

You are a senior product designer specializing in trustworthy, financial mobile apps. Design the complete visual UI and design system for **BetBook**, a mobile app. Produce a coherent, production-grade Material 3 design with named design tokens, component specs, and full-screen mockups in **both light and dark** themes. The output will be handed directly to a Flutter developer, so favor clarity, precision, and reusable tokens over one-off decoration.

## THE APP IN ONE SENTENCE

BetBook helps a person **track their deposits and withdrawals across different gambling / betting sites** so they can see, honestly and clearly, whether they are **up or down overall** — all stored **100% locally on the device**.

## THE SIGNATURE INTERACTION — CARD-DECK NAVIGATION (hero)

The **primary navigation between top-level sections** (Dashboard, Sites, Stats, Settings, and any other main section) is BetBook's signature interaction: each section is presented as a **full-bleed playing card**, and the user **swipes horizontally between the cards — like flipping through a deck of playing cards** — to move between sections. This is the app's hero moment. It nods to the betting/gambling theme (playing cards) while staying **classy and restrained, never casino-flashy** — think a beautifully printed deck, not a neon slot machine.

Design this explicitly and prominently:
- **Full-bleed section cards**: each top-level section lives on its own card that fills the screen, with a subtle card-like frame (refined corner radius, a quiet border/edge, tasteful surface). The card *contains* that section's content (e.g. the Dashboard card holds the hero P/L, totals, sparkline, and site summary).
- **Swipe / peek affordance**: at rest, show a **sliver of the adjacent cards' edges** on the left/right so it's obvious the deck continues and is swipeable. Design the **peek / mid-transition state** as an explicit mockup — cards sliding, the incoming card growing to full size and the outgoing one shrinking to a peek.
- **Active-section indicator**: a discreet indicator of where you are in the deck — **page dots, or better, a subtle card-suit / mini-card motif** (e.g. ♠ ♥ ♦ ♣ or small card glyphs) marking each section. Keep it quiet and elegant.
- **Physics & feel**: smooth **spring physics** with a slight settle, a gentle scale/parallax between the active card and its peeking neighbors, and light tactile feedback. Momentum should feel like fanning a real deck — never jittery.
- **Light & dark**: design the deck, card frames, edges, peek shadows/edges, and the indicator in **both themes**. In dark mode the card edges and peek must remain clearly readable without heavy shadows.
- **Optional touch of theme**: a tasteful playing-card suit or corner-pip motif on the card frame is welcome **if** it stays subtle and premium; do not turn cards into literal poker cards or add face-card art.

**Scope boundary:** only the **top-level sections** live in the swipeable deck. Individual feature/detail screens — **Add / edit transaction, Site detail, Add / edit site, Onboarding, and the App-lock screen** — are **normal full-screen routes pushed on top** of the deck (standard Material push/modal transitions), not cards in the deck. Make this distinction clear in the mockups.

## WHAT MATTERS MOST

1. **Trust and honesty.** This is a personal finance ledger for a sensitive, often stressful topic. The numbers must be legible at a glance and never feel like they are being spun.
2. **Calm, not casino.** Deliberately **not** flashy, glittery, neon, or "win big" energy. No slot-machine motifs, no gold coins raining, no confetti on a loss, no dark-pattern nudges to "keep playing." The aesthetic should quietly discourage gambling glamorization. Think **modern fintech / banking / expense-tracker**, muted but confident.
3. **Performance-minded.** Prefer flat fills, simple shapes, and lightweight charts over heavy gradients, blurs, and shadows that are expensive to render on mid-range Android.
4. **Legibility over decoration.** The data is financial and sensitive. When in doubt, make it clearer, not prettier.

## PLATFORM & CONSTRAINTS

- **Mobile-first**, portrait-primary. **Android is the first target** (Material 3), iOS second. Design at a common Android logical size (e.g. **360 × 800 dp**), and note behavior for larger phones.
- **Material 3 (Material You)** foundations: M3 color roles, state layers, rounded components, M3 typography scale. You may define a custom seed/brand color but must map cleanly onto M3 roles.
- **Light + Dark** are both first-class. Design every screen in both. Dark is not an afterthought — many users will check late at night.
- **Bilingual: English + Danish.** Copy is chosen at first launch. **Danish strings run ~15–35% longer** than English. Never design labels, buttons, chips, or tab bars that only fit the English text — show at least one Danish example per key screen and leave room for wrapping / truncation.
- **Offline, no accounts, no cloud.** There is no sign-in, no avatar, no social layer, no ads. Do not design any of these.

## BRAND & PERSONALITY

- **Feel:** trustworthy, calm, precise, grown-up, quietly modern. A tool a responsible adult uses to face reality.
- **Voice in UI copy:** plain, supportive, non-judgmental, never hyped. "You're down 1.240 kr this month," not "Oof, rough month!" Avoid gambling jargon where a plain word works.
- **Color usage:** a restrained neutral base with **one calm brand accent** (suggest a muted teal / slate-blue / deep indigo family — propose the exact hue). Reserve saturated color almost entirely for the **profit / loss semantics**, so money status is the loudest thing on screen and nothing competes with it.
- **No gambling clichés:** avoid dice, cards, roulette, chips, dollar-sign glitter, neon, and "jackpot" gold. A calm ledger/book or chart-line motif for the app mark is welcome.

---

## DESIGN SYSTEM TO DELIVER

Define a single, coherent system and **name every token** (e.g. `color.profit`, `space.4`, `radius.card`, `type.display.pl`). Reuse tokens across screens.

### 1. Color palette

- A full **Material 3 ColorScheme for both light and dark**: `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondary`(+container), `tertiary`(+container), `surface`, `surfaceContainerLowest/Low/High/Highest`, `surfaceVariant`, `outline`, `outlineVariant`, `error`(+container), `onSurface`, `onSurfaceVariant`, and the inverse roles. Provide **hex values** for every role in both themes.
- **Semantic money colors** — the heart of this app — as their own named tokens, because Material 3 has **no native profit/loss slot**:
  - `color.profit` (gain) and `color.profitContainer` / `onProfit` / `onProfitContainer`
  - `color.loss` (down) and `color.lossContainer` / `onLoss` / `onLossContainer`
  - `color.neutral` (exactly break-even / zero)
  - Provide light **and** dark values for each, all meeting **WCAG AA (4.5:1)** against the surfaces they sit on.
  - **Colorblind-considerate:** do not rely on red/green hue alone. Choose a green and red that also differ in **lightness/value**, and pair every profit/loss figure with a **`+` / `−` sign and a directional icon** (e.g. trend-up / trend-down) so meaning survives grayscale. Consider a teal-leaning positive and an orange-leaning negative if it improves deuteranopia distinguishability — propose and justify your choice.
- A small **data-visualization categorical palette** (6–8 hues) for per-site charts, harmonious with the brand and distinguishable for the common color-vision deficiencies.

### 2. Typography

- A complete **type scale mapped to M3 roles** (`displayLarge` … `labelSmall`), with font family, weight, size (sp), line height, and letter-spacing.
- Choose a **clean, legible, Google-Fonts-available** family (e.g. Inter, Manrope, or similar) with an explicit fallback, so the Flutter dev can wire it via `google_fonts` or bundle it. Note the fallback to the platform default.
- Define a dedicated **tabular / lining-numerals treatment** for all money figures so digits align in columns and totals don't jitter. Call out the specific styles used for: the **hero P/L figure**, secondary totals, list-row amounts, and chart axis labels.

### 3. Spacing, layout, shape, elevation

- A **spacing scale** (suggest a 4dp base: 4/8/12/16/24/32/48) as named tokens, plus standard screen padding and list-row rhythm.
- **Corner radius** tokens (e.g. card, sheet, button, chip, field) and an **elevation / surface-tint** scheme for both themes (prefer M3 tonal elevation over heavy drop shadows).
- A responsive note for small vs. large phones (and a graceful hint for tablet/landscape, even if out of scope).

### 4. Components (spec each with states: default, pressed, focused, disabled, error where relevant)

- **App bars** (large + small), the **card-deck navigation** (see the signature-interaction section: full-bleed section cards, peek affordance, active-section suit/dot indicator, spring physics — spec the card frame, edge/peek, and indicator here), and the **primary FAB** ("Add transaction").
- **Cards**: the hero P/L card; site summary card; stat cards.
- **List items**: site row (icon/color, name, currency badge, per-site net with sign+icon) and transaction row (type icon, amount with sign, date, optional note).
- **Buttons**: filled, tonal, outlined, text; segmented control / **type toggle (Deposit ↔ Withdrawal)**.
- **Chips**: currency badge, date-range filter chips, category filters.
- **Inputs**: text field, amount field (big number-pad feel), currency picker, color picker, icon picker, date/time picker.
- **Charts**: profit-over-time **line/sparkline**, per-site **bar** breakdown, monthly **summary**. Specify axis, gridline, label, and series styling; keep them lightweight.
- **Sheets & dialogs**: bottom sheet (add/edit), confirmation dialog (destructive delete), snackbar/toast.
- **Empty states** for: no sites yet, no transactions yet, no stats yet (illustration + one supportive line + a clear primary action).
- **Micro-interactions:** subtle, purposeful only — a gentle count-up on the hero figure, a smooth sign/color transition when a total crosses zero, tactile press states. **No celebratory animation on gains and nothing that dramatizes a loss.**

### 5. Iconography

- A consistent icon set (Material Symbols is the safe default). List the specific icons for: deposit, withdrawal, profit-up, loss-down, per site-category defaults, settings sections, backup, lock, and empty states.

---

## SCREENS TO DESIGN

Design **all** of the following, each in **light and dark**. For every screen, show the primary state and note key alternate/empty/error states. Include at least a few screens rendered with **Danish** copy to prove the longer strings fit.

### 1. Onboarding / first run
Minimal, elegant, a few **swipeable steps**. Steps: (a) short welcome + one-line value prop; (b) **language picker** EN / DA; (c) **theme picker** system / light / dark with live preview; (d) **base-currency picker** (default **DKK**). Progress indicator; "Get started" CTA. Calm, spacious, reassuring — mention that data stays on the device.

### 2. Dashboard (home)
The most important screen. Show:
- A **big overall P/L figure** in the base currency — **green when up, red when down**, with sign and directional icon — as the hero element.
- Supporting totals: **total deposited** and **total withdrawn**.
- A compact **profit-over-time sparkline / mini chart**.
- A **summary list of sites** with per-site net (sign + icon + currency badge).
- A prominent **"Add transaction" FAB**.
- Design the **empty first-run dashboard** (no data yet) as a distinct, welcoming state.

### 3. Sites list
All gambling sites as rows: **icon/color, name, currency badge, per-site net P/L** (sign + icon). Sort/summary at top if useful. An **"Add site"** action. Empty state.

### 4. Site detail
One site's **transaction history in chronological order**, a **running net**, **deposit total** and **withdrawal total**, the site's currency, and **edit / delete site** actions (delete is destructive → confirmation). Empty state (site exists, no transactions).

### 5. Add / edit transaction
Fast, keyboard-friendly, **big number-pad feel**. Fields: **type toggle Deposit ↔ Withdrawal**, **amount** (large, prominent), **site** (selectable, with **create-on-the-fly**), **date/time** (default now), **optional note**. Clear primary "Save". Show both the add and edit variants.

### 6. Add / edit site
Fields: **name**, **currency**, **color**, **icon / logo** (from a preset set). Live preview of the resulting site row. Save / cancel.

### 7. Stats
- **Profit-over-time line chart.**
- **Per-site bar breakdown.**
- **Monthly summary.**
- **Best / worst site** highlight.
- **Date-range filters** (chips: e.g. 1M / 3M / 6M / 1Y / All + custom).
- Empty / not-enough-data state.

### 8. Settings
Grouped sections:
- **General:** language (EN/DA), theme (system/light/dark), base currency.
- **Exchange rates:** an **editable table** of currency → base-currency rates (offline, user-editable), with last-edited hint.
- **Security:** app lock on/off, biometric / PIN.
- **Data:** backup / export (JSON/CSV), import, **clear data** (destructive → strong confirmation).
- **Responsible gambling:** optional **deposit limits** and **net-loss alerts**, presented supportively, never gamified.
- **About:** app **version + build number**, licenses, and a clear privacy note — **"All data stays on your device."**

### 9. App lock screen
**Biometric prompt** (fingerprint / face) with a **PIN fallback** entry. Locked, wrong-PIN error, and fallback states. Calm and secure-feeling, not alarming.

---

## RESPONSIBLE-DESIGN GUARDRAILS (must follow)

- No mechanics or visuals that **encourage** depositing or gambling. Deposit and withdrawal are shown as **neutral facts**, not wins.
- **Losses are shown honestly** — clear red/`−`, but never mocking, shaming, or dramatized. **Gains are shown calmly** — clear green/`+`, but no celebration, coins, or confetti.
- Responsible-gambling tools should feel **caring and easy to enable**, never buried and never gamified.

## DELIVERABLES (structure your response like this)

1. **Design language summary** — brand feel, the one-accent + money-semantics color strategy, and the key principles in a short paragraph.
2. **Design tokens**, clearly named and tabulated:
   - Full **ColorScheme** (light + dark) with hex.
   - **Semantic money tokens** (profit / loss / neutral, + containers, light + dark, with contrast notes).
   - **Categorical chart palette.**
   - **Typography** scale (family, weights, sizes, line-height, letter-spacing, tabular-figure note).
   - **Spacing, radius, elevation** scales.
3. **Component specs** with states, per the component list above.
4. **Screen mockups** — every screen above, **light and dark**, with Danish examples where noted. Label each with its screen name. **Include the card-deck navigation explicitly**: a resting state (active section card with adjacent cards peeking at the edges + active-section indicator) and a **mid-swipe / transition state** showing cards sliding and scaling — in both themes.
5. **A handoff-ready token sheet** (a compact list/table a developer can transcribe into Flutter `ColorScheme`, `TextTheme`, and a `ThemeExtension` for money colors) — hex values, not just swatches.
6. **A complete design handoff document, returned as a structured Markdown file** (a `DESIGN_HANDOFF.md`) that a Flutter developer can implement directly from, with no follow-up questions. This is a required, standalone deliverable — do **not** fold it into prose; produce it as its own downloadable/copyable Markdown artifact. It must contain, at minimum:
   - **Finalized design tokens** — the full **ColorScheme for light AND dark in hex** (every M3 role), the **semantic money tokens** (profit / loss / neutral + containers + on-colors, both themes, in hex, with the WCAG contrast ratio each achieves), the **categorical chart palette** in hex, the **typography scale** (family + fallback, and per-role weight / size / line-height / letter-spacing / tabular-figure note), and the **spacing, corner-radius, and elevation** scales — all clearly named.
   - **Component specs** for every component, with states (default / pressed / focused / disabled / error).
   - **Per-screen specs** — for each screen, the elements present, which tokens/components it uses, and its empty/error states.
   - **The card-deck navigation spec** — card frame, edge/peek behavior, active-section indicator, transition/scale behavior, and both-theme treatment — described precisely enough to build.
   - **Accessibility notes** (contrast results, the never-color-alone sign+icon rule, min tap targets, text-scaling behavior) and any **iconography / asset** references.

> Return BOTH: **(1)** the visual mockups/screens (deliverable 4), and **(2)** the structured `DESIGN_HANDOFF.md` Markdown (deliverable 6). Both are mandatory; the Markdown handoff must stand on its own so it can be dropped straight into the codebase.

Keep it coherent: one system, reused everywhere. Prioritize **clarity, legibility, and calm** over decoration at every step.
