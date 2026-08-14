# BetBook — Quick-add & Repeat-last

Self-contained spec for the two logging accelerators. Companion to `DESIGN_HANDOFF.md` (tokens, components, the full editor) and `MOTION_HANDOFF.md` (motion). `CLAUDE.md` still binds — in particular rule 4: **nothing here may encourage depositing.** These features remove friction from *recording* money that has already moved; they never suggest moving more.

Visual reference: `mockups/betbook-features.html` § Quick-add.

---

## 1. Decisions

### 1.1 Surface — a bottom sheet from the FAB

**Chosen: modal bottom sheet, 78% height, rising from the FAB's band.**

- The FAB already sits centred in its own band above the suit indicator; a sheet rises from exactly there, so the gesture and the surface share an origin.
- An **expanded FAB menu** would float items over the deck card and compete with the deck's horizontal swipe — two gestures in the same 200 dp of screen.
- **Inline on Dashboard** would eat the card's vertical space permanently for a task performed a few times a day, and would put the amount entry in the *top* half, away from the thumb.
- A sheet also gives the keypad the room it needs, and its dismissal (drag down / scrim) is the "never mind" affordance a persistent inline form lacks.

The FAB's **tap** opens quick-add. The full editor is one labelled tap away inside it (§2.6). The FAB's long-press does nothing — see 1.2.

### 1.2 Repeat-last trigger — an action on the most recent row

**Chosen: a trailing 40 dp `replay` icon button on the *first* row of Dashboard's recent activity only**, plus "Gentag" in the long-press menu of *any* transaction row (the menu already exists for edit/delete).

- It is visible without being taught: it sits on the thing it repeats.
- **FAB long-press** was rejected outright — an invisible gesture that commits money.
- **A chip inside the quick-add sheet** was rejected: by the time you have opened quick-add, you are already three taps from done, so the accelerator saves nothing.
- Only the first row carries the button, so the list keeps its rhythm and there is exactly one "repeat" affordance on screen.
- **Empty state solves itself**: with no transactions there is no recent list, so no trigger exists. Never a disabled button, never a greyed row.

### 1.3 Amount presets — recall only, per site, max 3

**Chosen: the 3 most recent *distinct* amounts for the selected site, newest first**, under a plain header *"Seneste beløb"* / *"Recent amounts"*.

Recall, not suggestion. The rules that keep it that way:

- Ordered by **recency**, never by size, never by frequency — a "most common amount" is a recommendation with statistics attached.
- **No round-number generation** (100 / 200 / 500). Those are amounts the user has not chosen, i.e. suggestions.
- Hidden entirely when the site has fewer than **2** distinct amounts, or no site is selected.
- Chips are neutral (`quick.preset.fill`), tabular, no icon, no "most used" star, no colour.
- Never shown for withdrawals *and* deposits mixed: the list is scoped to the **currently selected type**, so a deposit preset can never be tapped into a withdrawal.

### 1.4 Default site

In order, first match wins:

1. Opened from a **site detail** screen → that site.
2. Otherwise the site of the user's **last logged transaction** (`lastUsedSiteId`, written on every commit from any path).
3. No sites yet, or the last-used site was deleted → **no site selected**; the site row renders its empty state and the Save action is disabled until one is chosen.

"Most active site" was rejected: it changes under the user without their doing anything, and a silently pre-selected wrong site is the one error in this flow that corrupts data rather than wasting a tap.

---

## 2. Quick-add sheet

`surfaceContainerHigh`, `radius.sheet` top corners, scrim 32% light / 50% dark, 4 × 32 drag handle in `outlineVariant`. Height 78% of the viewport (never full-screen — the visible deck edge above it is what says "this is a shortcut, not a route"). Portrait only. Everything interactive sits in the **lower 60%**.

Layout, top to bottom:

| # | Element | Spec |
|---|---|---|
| 1 | Handle + title | *"Ny postering"* `titleLarge`, 16 top padding, centred handle above |
| 2 | **Type toggle** | the existing segmented deposit/withdrawal control, full width, height 44. Deposit is default (it is the more common entry, and it is the neutral choice — never preselect the one that reads as a "win") |
| 3 | **Amount display** | right-aligned, `type.amount.input` 52/800 tabular, `onSurface`; currency suffix `titleMedium onSurfaceVariant`. Empty shows `0` at 38% opacity. Never coloured — an individual deposit or withdrawal is not a net figure |
| 4 | **Recent amounts** | §1.3. `Wrap(spacing: 8)`, chips 32 dp, `quick.preset.fill` / `quick.preset.label`, tabular. Tapping replaces the amount (does not append) |
| 5 | **Site row** | 56 dp tap target: mini playing-card avatar 32 × 44 (`MOTION_HANDOFF.md` §3) + name `titleMedium` + currency `bodySmall onSurfaceVariant`, trailing `unfold_more` 20 in `onSurfaceVariant`. Tapping opens the compact site picker (§2.4) |
| 6 | **Date caption** | *"Dateres nu · i dag 21:34"* `bodySmall onSurfaceVariant`, **not** interactive. Setting a date is a full-editor job; a date picker here would rebuild the full editor inside the sheet |
| 7 | **Keypad** | the existing custom keypad, unchanged styling: 4 × 3 grid, `titleLarge` digits on `surfaceContainerHigh`, 48 dp min targets, `⌫` bottom-right, decimal separator locale-aware. The OS keyboard is never summoned |
| 8 | **Actions** | `Flere felter` text button (`primary`, left) · `Gem` filled button (right, `primaryContainer`/`onPrimaryContainer`, height 44). Bottom safe padding 24 |

### 2.1 States

| State | Rendering |
|---|---|
| **Empty** (no amount) | `Gem` disabled per `DESIGN_HANDOFF.md` §3.6 (1 dp `outlineVariant`, label 38%). Amount shows `0` at 38%. No error text yet |
| **Filled** | `Gem` enabled. Amount in `onSurface`, tabular |
| **No site** | site row shows *"Vælg site"* in `onSurfaceVariant` with the avatar slot as a 32 × 44 `outlineVariant` dashed placeholder; `Gem` disabled |
| **Validation on attempted save** | tapping a disabled `Gem` is possible (it is `enabled: false` visually but wrapped in a tap region) and scrolls/points to the first offending field with a `bodySmall error` line: *"Indtast et beløb"* / *"Vælg site"*. One line, no red fill, no shake, no haptic |
| **Saving** | `Gem` label swaps to a 16 dp `primary` suit-loader (`MOTION_HANDOFF.md` §4.1, small) for the duration of the local write — typically one frame, so only render it after 120 ms |
| **Success** | sheet dismisses (§4), then the existing SnackBar: *"Postering gemt"* with `FORTRYD` / `UNDO`, `inverseSurface`, 4 s. No tick animation, no confirmation screen, no sound |

### 2.2 Amount rules

Minor units, max 9 digits, `⌫` deletes one digit, long-press `⌫` clears. `0` alone is not saveable. Decimal separator follows locale (`,` in Danish). Tapping a preset chip replaces the value entirely, and a second tap on the same chip does nothing (never doubles).

### 2.3 Site picker (compact)

A nested sheet, `surfaceContainerHigh`, max 60% height: search field only when > 8 sites, then a list of 56 dp rows — mini-card avatar + name + currency, current selection carrying a trailing `check` in `primary`. `+ Nyt site` as the last row, pushing the existing add-site route (returning selects the new site). Selecting closes the nested sheet only; the quick-add sheet keeps every entered value.

### 2.4 Escape hatch — `Flere felter` / `More fields`

Pushes the **existing full-screen editor**, pre-filled with amount, type, site and the implicit date (now), focus placed on the note field. The quick-add sheet closes as the route pushes; **nothing is saved on the way through**. Returning from the editor — saved or cancelled — lands on the deck, never back in the sheet.

The label is deliberately `Flere felter`, not `Avanceret`: the full editor is not an expert mode, it is the same form with date and note.

### 2.5 Where the FAB goes

While the sheet is open the FAB fades and scales `1.0 → 0.94` over 160 ms and is removed from the tree (it is behind the scrim and would be a second, dead "add"). It returns on dismissal with the same 160 ms fade. No icon morph, no rotation.

---

## 3. Repeat-last

### 3.1 The trigger

On the first row of Dashboard's recent activity: a trailing 40 dp icon button, `replay` 20 dp in `onSurfaceVariant`, inside the row's trailing cluster after the amount, 8 dp gap. Pressed state = 12% `onSurface` circular state layer. `Semantics`: *"Gentag denne postering"* / *"Repeat this entry"*. It never appears on any other row; long-press any row for the same action via the existing menu.

### 3.2 Confirm step — always

A **compact confirm sheet** (not a dialog: thumb reach, and it matches quick-add's family). `surfaceContainerHigh`, `radius.sheet`, auto height:

```
Gentag postering                       titleLarge
┌──────────────────────────────────────────────┐   quick.summary.fill, radius.card, padding 14
│ [♠ D]  Danske Spil                           │   avatar 32×44 + titleMedium
│        Indbetaling · dateres nu, i dag 21:34 │   bodySmall onSurfaceVariant
│                                    500 kr    │   type.row.amount, onSurface, tabular
└──────────────────────────────────────────────┘
        Redigér                          Gem      text button · filled button
```

- Amount is `onSurface` — it is a single movement, not a net figure. No sign, no trend icon, no colour.
- `Redigér` opens **quick-add pre-filled** with the same values (one step back into the editable path, keypad ready).
- `Gem` commits with `date = now` and shows the same *"Postering gemt"* + Undo SnackBar.
- There is no one-tap commit anywhere in this feature. A mis-tap that silently writes a 500 kr deposit is the one failure mode worth a whole extra tap.
- Note and tags from the source transaction are **not** copied: they described that entry, not this one. The confirm sheet says so implicitly by showing exactly what will be written and nothing else.

### 3.3 Empty / unavailable

No transactions → no recent list → no trigger. A deleted source transaction (undo window race) → the trigger disappears with the row. Never a disabled repeat button.

---

## 4. Motion

Consistent with the deck: one soft settle, no bounce, no overshoot.

| Transition | Value | Reduced motion |
|---|---|---|
| Sheet in | slide up 24 dp + fade `0 → 1`, **260 ms** `easeOutCubic`; scrim fades over the same 260 ms | sheet and scrim at final position immediately |
| Sheet out (dismiss or save) | slide down 24 dp + fade, **200 ms** `easeOutCubic` | removed instantly |
| FAB during | fade + scale `1.0 → 0.94`, 160 ms, both directions | hidden/shown instantly |
| Nested site picker | standard M3 nested-sheet transition, 240 ms | instant |
| Preset chip tap | amount cross-fades 120 ms (digits only, tabular so nothing shifts) | value swaps instantly |
| Confirm sheet | same 260 / 200 ms as quick-add | instant |
| Save → SnackBar | existing SnackBar transition, unchanged | unchanged (SnackBar is not motion-dependent) |
| Haptics | **none** in this feature. Deck settle and refresh-armed remain the only two | — |

`Motion.of(context)` from `flutter/deck_motion.dart` returns `Duration.zero` when animations are disabled, so all of the above collapse without branching.

---

## 5. New tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `quick.preset.fill` | `#E9E7EC` (`surfaceContainerHigh`) | `#292A2F` | recent-amount chip |
| `quick.preset.label` | `#1A1B20` (`onSurface`) | `#E3E2E6` | amounts read as values, so full-strength ink, tabular |
| `quick.summary.fill` | `#FFFFFF` (`surfaceContainerLowest`) | `#1E1F25` | the repeat-last summary block |
| `quick.summary.outline` | `#C4C6D0` @ 70% | `#44474F` | 1 dp around the summary block |
| `quick.sitePlaceholder` | `#C4C6D0` | `#44474F` | 32 × 44 dashed avatar slot, 1 dp, radius 6 |

Everything else — sheet fill, scrim, buttons, keypad, avatar, SnackBar — is existing tokens unchanged.

---

## 6. Localisation

| Key | English | Danish |
|---|---|---|
| `newEntry` | New entry | Ny postering |
| `deposit` / `withdrawal` | Deposit / Withdrawal | Indbetaling / Udbetaling |
| `recentAmounts` | Recent amounts | Seneste beløb |
| `chooseSite` | Choose site | Vælg site |
| `newSite` | New site | Nyt site |
| `datedNow` | Dated now · today {time} | Dateres nu · i dag {time} |
| `moreFields` | More fields | Flere felter |
| `save` | Save | Gem |
| `enterAmount` | Enter an amount | Indtast et beløb |
| `selectSite` | Choose a site | Vælg site |
| `entrySaved` | Entry saved | Postering gemt |
| `undo` | UNDO | FORTRYD |
| `repeatEntry` | Repeat entry | Gentag postering |
| `repeatThisEntry` | Repeat this entry | Gentag denne postering |
| `edit` | Edit | Redigér |

Sizing consequences: `Indbetaling` / `Udbetaling` are +37% on the type toggle — the segments are `Expanded` with `FittedBox(scaleDown)` at `textScaleFactor 1.3` and **never** truncated; `Flere felter` and `Gem` sit in a `Row` with the text button allowed to wrap to two lines rather than clip; `Dateres nu · i dag 21:34` is a single `bodySmall` line that ellipsises from the middle if a 24 h locale plus long day name overflows on a 320 dp screen.

---

## 7. Implementation notes

- Both accelerators write through the **same** repository method as the full editor — one validation path, one Undo path, one `lastUsedSiteId` write. No parallel insert code.
- `lastUsedSiteId` and the per-site recent-amount list are derived at read time from the transactions table (`DISTINCT amount ... ORDER BY date DESC LIMIT 3`), not stored — nothing to keep in sync, nothing to migrate.
- The keypad, mini-card avatar, segmented toggle, SnackBar and site row are **existing widgets reused as-is**. If quick-add needs a variant of one of them, change the shared widget, don't fork it.
- Quick-add state lives in the sheet's own controller and is discarded on dismiss — no draft persistence. A dismissed sheet losing 4 keypad taps is acceptable; a resurrected half-entry that the user forgot about is not.
