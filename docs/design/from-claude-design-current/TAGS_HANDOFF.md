# BetBook — Tags & tag-filtered Stats

Self-contained spec for the tags feature. Companion to `DESIGN_HANDOFF.md` (tokens, components, screens) and `MOTION_HANDOFF.md` (motion). Every rule in `CLAUDE.md` still binds — in particular: money colour only on net figures, and nothing gamified.

Visual reference: `mockups/betbook-tags.html` (light + dark, every screen below).

---

## 1. Decisions

### 1.1 What can be tagged — transactions, many tags each

Tags live on the **transaction**, many-to-many. A tag on a site would be redundant (the site is already an identity with a colour and a card chip), and a tag on a "session" would require a concept the data model does not have.

**Sites carry one optional `defaultTagId`.** New transactions for that site prefill it as a normal, removable chip. This is where almost all the value is — a poker room's transactions are nearly always `poker` — and it costs one nullable column. The prefilled chip looks identical to a user-added one; it is never locked, and editing a site's default never rewrites existing transactions.

### 1.2 How many

| Limit | Value | Why |
|---|---|---|
| Hard cap per transaction | **5** | past five the picker's assigned row wraps to three lines on Danish strings |
| Soft guidance | 1–2 | the add screen shows no counter and no warning below the cap — this is guidance for copy and defaults, not a UI rule |
| Total tags | no cap | the picker sorts by use, so a long tail costs nothing |
| Tag name | 1–24 characters, trimmed, case-insensitively unique | `Poker` and `poker` are the same tag; first-created casing wins |

**Display rule.** Dashboard recent list and site-detail list show **up to 2** micro-chips, then a plain `+N` in `onSurfaceVariant` (not a chip — a chip that says "+2" reads as a tag called "+2"). Site detail has no site name on the row, so it shows **up to 3**, then `+N`. Overflow order is assignment order, stable. If the row's tags would push the amount out of position, drop to 1 chip + `+N` before ever shrinking the amount.

### 1.3 Tag colour — neutral chips, optional identifying dot

Tags are **neutral**: `surfaceContainerHigh` fill, `onSurfaceVariant` label. Colour in this app means one of two things already — money direction or site identity — and a third coloured chip system beside a `−920 kr` in rust orange is exactly how a calm ledger starts looking like a bookmaker's app.

But a wall of grey chips is unscannable, so a tag may carry **one 6 dp leading dot** from a fixed six-hue palette. The palette deliberately contains **no green and no orange-red**, so a dot can never be misread as profit or loss. The dot is decorative: the tag's name is always visible beside it, and the dot is never the only carrier of identity (a11y and `CLAUDE.md` rule 2 by extension).

| Token | Light | Dark | Contrast on chip fill |
|---|---|---|---|
| `tag.dot.blue` | `#3B5F9E` | `#A8C4FF` | 4.8:1 / 6.1:1 |
| `tag.dot.indigo` | `#4E4E8F` | `#B6B7F2` | 6.9:1 / 6.6:1 |
| `tag.dot.violet` | `#6F5675` | `#DDBCE0` | 5.6:1 / 7.4:1 |
| `tag.dot.plum` | `#9A3B63` | `#F3A0C0` | 5.0:1 / 6.8:1 |
| `tag.dot.ochre` | `#8A6D1F` | `#DFC169` | 4.6:1 / 7.1:1 |
| `tag.dot.slate` | `#4A6572` | `#9FB6C2` | 5.4:1 / 6.3:1 |
| `tag.dot.none` | — | — | dot omitted entirely (default for new tags) |

Dots are **opt-in**: a new tag has no dot. The colour is picked in tag management from these six plus "no colour" — a fixed six-swatch row, never a free picker. Store the enum name (`blue`), never an ARGB int, so a theme swap resolves correctly.

### 1.4 Filter model — multi-select, OR, max 3

Selecting tags on Stats filters to transactions carrying **any** of them ("any of"). Rationale:

- **AND is near-useless here**: with 1–2 tags per transaction in practice, `fodbold AND live` matches almost nothing, and users read an empty chart as a bug.
- **OR is how people actually group**: `fodbold` + `kombi` = "my football betting, however I placed it".
- **Multi-select, capped at 3.** One tag would force repeated visits to compare related activities; more than three selected and the hero figure stops meaning anything specific.

The header always states the model in words — `Kun: fodbold, live` for one or two, `Alle tags` when unfiltered — so no user has to infer AND vs OR. There is no AND toggle; if that need ever appears it is a separate feature, not a hidden mode.

---

## 2. New tokens

All other values come from `DESIGN_HANDOFF.md`. Nothing here overrides an existing token.

| Token | Light | Dark | Note |
|---|---|---|---|
| `tag.chip.fill` | `#E9E7EC` (`surfaceContainerHigh`) | `#292A2F` | resting assigned chip |
| `tag.chip.label` | `#44474F` (`onSurfaceVariant`) | `#C4C6D0` | 4.5:1+ both themes |
| `tag.chip.fillSelected` | `#D8E2FF` (`primaryContainer`) | `#244777` | filter-selected only |
| `tag.chip.labelSelected` | `#001A41` | `#D8E2FF` | |
| `tag.chip.outline` | `#74777F` (`outline`) | `#8E9099` | unselected filter chip + "add tag" chip, 1 dp |
| `tag.chip.disabledOutline` | `#C4C6D0` (`outlineVariant`) | `#44474F` | label at 38% |
| `tag.dot.*` | §1.3 | §1.3 | 6 dp, `tag.dot.none` default |
| `tag.overflow.label` | `#44474F` | `#C4C6D0` | the `+N` text, `bodySmall` |
| `tag.filterBar.fill` | `#F4F3F7` (`surfaceContainerLow`) | `#1A1B20` | the Stats filter row background |

Sizes: `tag.chip.h` 32 · `tag.chip.hMicro` 20 · `tag.chip.hPicker` 36 · `tag.dot.d` 6 · `tag.chip.maxW` 148 (micro 116).

---

## 3. Tag chip component

Four variants, one visual family. Radius is always **full**.

| Variant | Where | Height | Label | Padding | Container |
|---|---|---|---|---|---|
| **Micro** | transaction rows | 20 | `labelSmall` 11/600 | 8 h (10 with dot) | `tag.chip.fill`, no outline |
| **Assigned** | add/edit transaction, tag management | 32 | `labelLarge` 14/600 | 12 l / 8 r (trailing ×) | `tag.chip.fill` |
| **Filter** | Stats filter row | 32 | `labelLarge` 14/600 | 14 h (12 l with dot) | unselected: 1 dp `tag.chip.outline`, transparent fill · selected: `tag.chip.fillSelected` + a 16 dp leading `check` |
| **Add** | add/edit transaction | 32 | `labelLarge` 14/600 | 10 l / 14 r | 1 dp `tag.chip.outline`, transparent, leading `add` 16 |

**States** (all variants): resting · pressed 12% `onSurface` state layer, 80 ms cross-fade · focused 3 dp `primary` outline, offset 2 · disabled 1 dp `tag.chip.disabledOutline` + label 38% (only when the 5-tag cap is reached — existing chips stay enabled, unpicked ones go disabled) · selected (filter only).

**Rules**
- Tap target ≥ 48 dp: chips sit in a row with `padding: 8 vertical` and the ink response fills the target, not the chip box. The micro chip in a transaction row is **not tappable** — the row is.
- **Max width** `tag.chip.maxW` then `TextOverflow.ellipsis`. Never scale the label down, never wrap inside a chip.
- Rows of chips use `Wrap(spacing: 8, runSpacing: 8)` — always wrapping, never a horizontal scroller with hidden content, never `Expanded` on a chip. This is the Danish-length insurance.
- The trailing `×` on an assigned chip is 18 dp inside a 32 dp square target; the chip's own tap opens nothing (assignment happens in the picker), so `×` is the only action.
- Never a count badge, a level, a streak, or a filled accent chip. A tag chip must look like a filing label.
- `textScaleFactor 1.3`: chip height grows with the label (min 32/20 becomes a minimum, not a fixed height); the `Wrap` absorbs it.

---

## 4. Assigning tags — add / edit transaction

The screen keeps its order: **amount keypad → type toggle → site → date → note**. Tags go **between date and note**, as its own labelled row:

```
Tags                                    (labelMedium, onSurfaceVariant)
[ ● poker × ] [ fodbold × ] [ + Tilføj tag ]      Wrap, 8/8
```

- **Empty state (no tags exist yet):** the row shows only the add chip, plus one line of `bodySmall onSurfaceVariant` beneath: *"Tags gør det muligt at filtrere Stats — fx fodbold eller poker."* / *"Tags let you filter Stats — e.g. football or poker."* The line disappears permanently once the first tag exists (`hasEverCreatedTag` flag, not a dismissal).
- **Prefill:** the site's `defaultTagId`, if set, appears as a normal removable chip as soon as a site is chosen. Changing the site swaps a prefilled chip that the user has not touched; it never removes a tag the user added or kept.

### 4.1 The picker (bottom sheet)

Tapping **+ Tilføj tag** opens a bottom sheet — `surfaceContainerHigh`, `radius.sheet`, drag handle, resizes with the keyboard:

1. **Search / create field** — outlined, `radius.field`, 56 dp, autofocused, `textCapitalization: none`, leading `search`, hint *"Søg eller opret tag"*.
2. **Results** — as the user types, a `Wrap` of matching tags (case-insensitive `contains`, prefix matches first). Unfiltered, it shows the **12 most-used** tags, most-used first, then an "Alle tags" row that pushes the management screen.
3. **Create row** — appears as the first item as soon as the query is a non-empty string with no exact match: `+ Opret "kombi"` in `primary`, `labelLarge`. Enter/done also creates. A query matching an existing tag case-insensitively selects that tag instead of creating a duplicate.
4. Tapping a tag assigns it and **keeps the sheet open** (the field clears, the assigned chip appears greyed in results) so two or three tags are one visit. The sheet closes on the handle, the scrim, or "Færdig".
5. At 5 assigned, unassigned results go disabled and a `bodySmall` line reads *"Højst 5 tags pr. postering."*

**Motion:** sheet is the standard M3 sheet transition. Assigning a tag inserts the chip with a 120 ms `easeOutCubic` fade only — no scale-in, no slide, no haptic. Removing (`×`) removes it instantly and offers no undo (it is one tap to re-add). **Reduced motion:** chip appears/disappears with no fade; sheet still uses the platform route transition.

---

## 5. Tag management

**Location:** Settings ♣ › *Data* › **Tags**, and reachable from the picker's "Alle tags" row. A pushed route, never a deck card.

Rows, 64 dp min, standard list-item states:

```
● poker                     18 posteringer        ›
  fodbold                   41 posteringer        ›
  bonus                      3 posteringer        ›
```

Sorted by use count desc, then name. Trailing chevron opens a **detail sheet** for that tag with: name field (rename, live-validated for uniqueness), the six-swatch dot row + "Ingen farve", *"Flet ind i et andet tag…"*, and *"Slet tag"* in `error`.

- **Rename** — commits on Done/blur; duplicate name shows an inline `error` helper *"Der findes allerede et tag med det navn."* and blocks the save. No confirmation needed; renaming is safe.
- **Delete** — a confirmation dialog (per `DESIGN_HANDOFF.md` §3.11) stating the consequence exactly: *"Tagget fjernes fra 18 posteringer. Posteringerne slettes ikke."* Then the existing **Undo SnackBar** pattern: `inverseSurface`, 4 s, action `FORTRYD` / `UNDO`, which restores the tag **and every assignment** (keep the removed join rows in memory until the snackbar closes; only then commit).
- **Merge** — worth having: users create `fodbold` and `football` within a week. Merge picks a target tag, moves assignments (deduplicating), deletes the source, and shows *"fodbold flettet ind i football"* with the same 4 s Undo. Merge is the one destructive action that is genuinely hard to redo by hand, which is why it earns its place.
- **Empty state** — brand suit mark, *"Ingen tags endnu"*, body *"Tilføj et tag, når du opretter en postering."*, no button (creating a tag here with nothing to attach it to is a dead end).

Copy is supportive and factual throughout — no "Are you sure?!", no warning icons.

---

## 6. Tags in the transaction row

Row height and rhythm are unchanged (min 64, 36 dp circular type icon, amount right, `onSurface`). Tags render on the **subtitle line**, after the date/time, separated by a 8 dp gap:

```
Indbetaling
14. aug · 21:30 · [poker] [fodbold] +1
                                        −500 kr
```

- Micro chips (20 dp) share the subtitle line with the date; if the note exists it moves to a third line and the row grows to 76 dp — the existing behaviour for notes, unchanged.
- Overflow per §1.2. Amount position, weight, colour (`onSurface`) and tabular figures are untouched: **tags never colour an amount and never shift it**.
- `Semantics` for the row appends `", tags: poker, fodbold, og 1 mere"` after the amount — one label, not per-chip nodes.
- Rows with no tags render nothing extra — no placeholder, no "add tag" affordance in the list (that lives in edit).

---

## 7. Tag filter on Stats ♦

### 7.1 The control

Directly **beneath** the existing range chips (which stay first — range is the coarser axis and must not move), in a `tag.filterBar.fill` strip, `radius.card`, padding 12:

```
Tags   [ ✓ fodbold ] [ ● live ] [ poker ] [ bonus ]        Ryd
```

- A `Wrap` of **filter** chips, most-used first, cap 12 visible then a `Alle tags…` chip opening a sheet with the full list (same picker component, multi-select mode).
- Selected chips move to the front of the wrap on selection **only when the sheet closes or the screen is re-entered** — never reordering under the user's finger.
- **`Ryd` / `Clear`** text button, right-aligned, `primary`, visible only when ≥ 1 tag is selected. It is the "All" reset — there is no "All" chip, because an "All" chip that is on by default trains people to think it is a real tag.
- Header line above the hero figure states the filter in words: `Alle tags` (unfiltered) or `Kun: fodbold, live` — `labelMedium onSurfaceVariant`, ellipsised after two names + `+N`.
- Max 3 selected; further chips go disabled with a `bodySmall` line *"Højst 3 tags ad gangen."*

**Persistence:** the range selection persists across launches (existing behaviour). **The tag filter does not** — it resets to unfiltered on cold start. A remembered filter means someone opens the app, reads `−340 kr`, and believes it is their total. Within a session it persists across deck swipes and pushed routes.

### 7.2 How each element re-reads

Filter = transactions whose tag set intersects the selection (OR), **and** the active range. Untagged transactions are excluded whenever a filter is active.

| Element | Under an active filter |
|---|---|
| **Hero net** | net of matching transactions only. Same `type.display.pl`, same money-colour rules, same count-up (§5 of `MOTION_HANDOFF.md`). Supporting line becomes *"fodbold, live · 23 posteringer"* |
| **Cumulative line chart** | series recomputed from matching transactions, rescaled to their own min/max. The unfiltered total is drawn **behind** as a 1 dp `outlineVariant @ 40%` reference line with no terminal dot and no tooltip — context without a second legend. Reference line is omitted if it would fall outside the rescaled axis |
| **Per-site breakdown** | only sites with ≥ 1 matching transaction; bars rescale to the filtered max, so a filtered view is never a row of near-empty tracks. A count line reads *"3 af 5 sites"* |
| **Best / worst** | best and worst **site** within the filter. With only one matching site, show the single card and replace the other with a `bodyMedium onSurfaceVariant` line *"Kun ét site med dette tag."*. Never invent a second |
| **Monthly bars** | filtered, but the **month axis does not change** — months with no matching transactions render an empty track in `surfaceContainerHighest` so the shape of the year stays readable and comparable |
| **Empty result** | all of the above collapse to one empty state (§7.3). The range chips and the filter bar stay visible and interactive — the way out must be on screen |

### 7.3 Empty state (tag has no transactions in range)

Brand suit mark 48, `headlineSmall` *"Ingen posteringer med dette tag"*, `bodyMedium` *"Prøv en anden periode eller ryd filteret."*, and a filled **Ryd filter** button. Range chips and filter bar remain above it. No illustration, no apology.

### 7.4 Motion

| Transition | Value | Reduced motion |
|---|---|---|
| Chip select/deselect | container + label colour cross-fade 120 ms `easeOutCubic`; leading `check` fades in over the same 120 ms with no slide | instant colour swap, check appears immediately |
| Filter apply → figures | hero re-counts per `MOTION_HANDOFF.md` §5 (400 ms) and the secondary wave follows (90 ms stagger) | all figures final immediately |
| Line + monthly charts | 220 ms `easeOutCubic` cross-fade of the whole painted layer (opacity only — no path morphing, no growing bars) | instant repaint, no fade |
| Per-site bars | bar widths animate 220 ms `easeOutCubic`; rows entering/leaving cross-fade over the same 220 ms, no slide | instant |
| Empty state | 150 ms cross-fade in | instant |
| Haptics | none anywhere in this feature | — |

---

## 8. Discoverability

Three passive touchpoints, no overlay, no coach mark, no tooltip:

1. **The add-transaction screen** is the teacher — the `Tags` row with its `+ Tilføj tag` chip is always visible while entering a transaction, with the one-line explainer until the first tag exists (§4).
2. **Stats shows a single inline hint** in place of the filter bar *only while the user has zero tags*: `bodySmall onSurfaceVariant` — *"Tag dine posteringer for at filtrere her."* No icon, no dismiss button; it is replaced by the real filter bar the moment a tag exists.
3. **Settings › Data › Tags** exists from day one with its empty state, so anyone browsing settings meets the concept.

Nothing about tags is ever advertised in a dialog, a banner, or a "New!" badge.

---

## 9. Localisation

Every string via ARB (`en`, `da`); nothing hardcoded, including the example tag names in explainer copy (they are localised examples, not data).

| Key | English | Danish |
|---|---|---|
| `tagsLabel` | Tags | Tags |
| `addTag` | Add tag | Tilføj tag |
| `searchOrCreateTag` | Search or create tag | Søg eller opret tag |
| `createTag` | Create "{name}" | Opret "{name}" |
| `allTags` | All tags | Alle tags |
| `onlyTags` | Only: {names} | Kun: {names} |
| `clearFilter` | Clear filter | Ryd filter |
| `clear` | Clear | Ryd |
| `maxTagsPerTx` | Up to 5 tags per entry. | Højst 5 tags pr. postering. |
| `maxTagsFilter` | Up to 3 tags at a time. | Højst 3 tags ad gangen. |
| `tagInUse` | A tag with that name already exists. | Der findes allerede et tag med det navn. |
| `deleteTagBody` | The tag is removed from {count} entries. The entries are not deleted. | Tagget fjernes fra {count} posteringer. Posteringerne slettes ikke. |
| `mergeInto` | Merge into another tag… | Flet ind i et andet tag… |
| `mergedInto` | {source} merged into {target} | {source} flettet ind i {target} |
| `noTagsYet` | No tags yet | Ingen tags endnu |
| `noEntriesForTag` | No entries with this tag | Ingen posteringer med dette tag |
| `tagsHintStats` | Tag your entries to filter here. | Tag dine posteringer for at filtrere her. |
| `entriesCount` | {count} entries | {count} posteringer |

Sizing consequences (Danish is the long one here): `Tilføj tag` +27%, `Højst 3 tags ad gangen.` +21%, `Der findes allerede et tag med det navn.` +38%. Therefore: chips wrap and never `Expanded`; the picker's helper lines are 2-line-safe; `Ryd` sits as a text button that can wrap under the chip wrap on a 320 dp screen; no chip row is ever a fixed-width `Row`.

---

## 10. Data & implementation notes

```
tags(id TEXT PK, name TEXT NOT NULL, name_folded TEXT UNIQUE, dot TEXT NULL, created_at INT)
transaction_tags(transaction_id TEXT, tag_id TEXT, position INT, PRIMARY KEY(transaction_id, tag_id))
sites: + default_tag_id TEXT NULL REFERENCES tags(id) ON DELETE SET NULL
```

- `name_folded` = trimmed, lowercased, `NFC`-normalised — the uniqueness key (`Poker` == `poker`; Danish `æøå` fold correctly under `toLowerCase()` with `Locale('da')`).
- `position` preserves assignment order for the overflow rule.
- Deleting a tag deletes its `transaction_tags` rows only; keep them in memory for the Undo window and re-insert on undo.
- Tag counts on the management screen come from one aggregate query, not N+1.
- Filtering is `WHERE tt.tag_id IN (?) ` + `DISTINCT` on the transaction — OR semantics fall out of the `IN`. Index `transaction_tags(tag_id)`.
- **No `IconData` is ever stored** (per `CLAUDE.md` icon rule): a tag is a name plus an optional dot enum. The only icons in this feature are `add`, `search`, `close`, `check`, `chevron_right` — all already in the app.
- The dot enum → colour resolution happens in the widget from the theme, so light/dark and future palette edits need no migration.
