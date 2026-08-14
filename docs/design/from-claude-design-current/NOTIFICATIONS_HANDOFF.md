# BetBook — Notifications: weekly summary & limit warnings

Self-contained spec for the two opt-in local notifications and their in-app surfaces. Companion to `DESIGN_HANDOFF.md` (tokens, Settings rows, cards) and `MOTION_HANDOFF.md` (motion). `CLAUDE.md` binds throughout: no celebration, no shaming, responsible-gambling tools stay easy to find and supportively worded.

Everything here is **generated on-device** from data already in the local store. No account, no server, no payload leaves the phone — and no copy anywhere may imply otherwise.

Visual reference: `mockups/betbook-features.html` § Notifications.

---

## 1. Decisions

### 1.1 Weekly summary timing — fixed, Monday 09:00 local

**No day/time picker in v1.**

- The week boundary is what makes the figure meaningful; letting people summarise "Wednesday to Wednesday" produces a number they cannot compare to anything.
- Monday 09:00 is after waking, before the day is loaded, and on the day people naturally review the past week.
- A picker adds a scheduling surface, a time-zone edge case, and exact-alarm handling for a once-weekly informational message. It can be added later without changing anything else here.

The Settings row states the schedule as plain text — *"Hver mandag kl. 09.00"* — so it is never a mystery. Delivery is inexact by design (`AndroidScheduleMode.inexactAllowWhileIdle`): a summary that arrives at 09:12 is fine, a summary that requires exact-alarm permission is not. If the phone was off, the plugin's next delivery is used; a missed week is **skipped**, never batched, and never sent twice for the same week (`lastSummaryWeekIso` guard).

### 1.2 Limit-warning thresholds — 80% and 100%, twice per period maximum

| Fire | Condition | Copy |
|---|---|---|
| **Approaching** | `periodDepositBase ≥ 0.80 × depositLimitBase`, first crossing in the period | §3.2 |
| **Reached** | `periodDepositBase ≥ depositLimitBase`, first crossing in the period | §3.2 |
| **Net-loss alert** | `netLossExceeded` becomes true, first crossing in the period | §3.2 |

- **Maximum two deposit notifications per period** (one at 80%, one at 100%) plus at most one net-loss alert. Nothing fires again at 150% or 300% — the user knows; repeating it is nagging, and nagging gets the whole channel muted, which costs them the warning that matters.
- **No escalation, no priority bump.** Both use the same channel at `Importance.defaultImportance`, no full-screen intent, no ongoing/sticky notification, no vibration pattern of its own.
- Crossing state is persisted per period (`rgNotifiedApproaching`, `rgNotifiedReached`, `rgNotifiedNetLoss`, all keyed by period start) and cleared when the period rolls over. Editing the limit **downward** into an already-crossed state does not re-fire; the in-app banner (§4) shows the truth immediately, which is the honest surface for a state the user just created themselves.
- Evaluated on **transaction commit** and on app resume — never by polling, never by a background worker.

### 1.3 Tone — stated, never dramatised

Three cases, and one rule per case: a loss is stated with the figure and a neutral next step; a win is stated with the figure and **no** praise; break-even is stated flatly. No "Oof", no "Great week!", no emoji anywhere in title or body (emoji in a notification is an alarm, and this is not an alarm).

Full copy in §3.1.

### 1.4 In-app pairing — yes, both, and they behave differently

- **Limit state → a persistent banner** on Dashboard, above the hero figure, for as long as the condition is true. Not dismissible: it is a *state*, not a message, and dismissing a state is how a user loses track of it. It links to Responsible gambling.
- **Weekly summary → a dismissible card** at the top of Dashboard for 48 h after the notification fires. It is a *message*, so it can be dismissed, and it disappears on its own.

Both work whether or not notifications were ever enabled — the in-app surfaces are not a reward for granting permission. This is the part that matters most: someone who denies notification permission still sees their limit state.

---

## 2. Settings

### 2.1 Rows

Under **Settings ♣ › Responsible gambling**, after the existing limit rows, in a new labelled group *"Påmindelser"* / *"Reminders"*:

| Row | Type | Subtitle |
|---|---|---|
| **Ugentligt overblik** / Weekly summary | `SwitchListTile` | *"Hver mandag kl. 09.00"* / *"Every Monday at 09:00"* |
| **Advarsler om grænser** / Limit warnings | `SwitchListTile` | *"Ved 80% og 100% af din indbetalingsgrænse"* |
| **Tag en pause** / Take a break | navigation row, trailing `chevron_right` | *"Skjul totaler og pause påmindelser"* (§5) |

Rows use the existing Settings row spec unchanged: 64 dp min, `titleMedium` label, `bodySmall onSurfaceVariant` subtitle, `Switch` in `primary`. The limit-warnings row is **disabled with a 38% label** when no deposit limit and no net-loss alert are configured, with the subtitle replaced by *"Sæt en grænse først"* / *"Set a limit first"* — the one place a disabled control is right, because the fix is a row away in the same screen.

### 2.2 Permission flow (Android 13+)

Turning on either switch for the first time does **not** call the OS dialog directly.

1. **Rationale sheet** (`surfaceContainerHigh`, `radius.sheet`, drag handle): brand suit mark 40, `headlineSmall` *"Påmindelser på din telefon"*, `bodyMedium`:
   *"BetBook laver påmindelserne på din telefon. Intet sendes til en server, og der er ingen konto."* / *"BetBook creates reminders on your phone. Nothing is sent to a server, and there is no account."*
   Actions: `Ikke nu` text button · `Fortsæt` filled button. `Fortsæt` calls `requestPermission()`.
2. **Granted** → switch turns on, schedule registered, sheet closes. No confirmation toast.
3. **Denied (soft)** → switch returns to off, no error, no scolding. A `bodySmall onSurfaceVariant` line appears under the row: *"Påmindelser er slået fra i systemindstillinger."*
4. **Blocked (permanently denied)** → same line plus a text button *"Åbn indstillinger"* / *"Open settings"* that deep-links to the app's notification settings. The switch stays off and tapping it re-opens the rationale sheet with the deep link as its primary action — never a dead toggle.
5. Permission is re-checked on resume; a user who granted it in system settings sees the switch become operable without restarting.

The rationale sheet appears **once per install** while permission is undetermined; after that the OS dialog (or the blocked state) is the whole flow.

---

## 3. Notification content

One channel per type, both `Importance.defaultImportance`, no badge count, no group summary, `autoCancel: true`.

| Channel id | Name (EN / DA) | Description |
|---|---|---|
| `weekly_summary` | Weekly summary / Ugentligt overblik | Your week in numbers, once a week |
| `limit_warnings` | Limit warnings / Advarsler om grænser | When you approach or reach a limit you set |

### 3.1 Weekly summary

Tapping → **Stats ♦** with the range set to *last week*. Deep link `betbook://stats?range=lastWeek`.

| Case | English title | English body |
|---|---|---|
| Loss | Last week: −1.240 kr | You're down 1.240 kr across 3 sites. Tap to see the week. |
| Win | Last week: +820 kr | You're up 820 kr across 2 sites. Tap to see the week. |
| Break-even | Last week: 0 kr | Deposits and withdrawals balanced out. Tap to see the week. |
| No activity | Last week | No entries last week. |

| Case | Danish title | Danish body |
|---|---|---|
| Loss | Sidste uge: −1.240 kr | Du er nede 1.240 kr på 3 sites. Tryk for at se ugen. |
| Win | Sidste uge: +820 kr | Du er oppe 820 kr på 2 sites. Tryk for at se ugen. |
| Break-even | Sidste uge: 0 kr | Ind- og udbetalinger gik lige op. Tryk for at se ugen. |
| No activity | Sidste uge | Ingen posteringer sidste uge. |

Rules: the sign is always present in the title (it is a net figure, and colour is unavailable in a notification — the sign and the word carry it). No adjectives on either side: not "tough", not "solid". The "no activity" case still fires because silence is information, and skipping it would make a missing notification ambiguous.

### 3.2 Limit warnings

Tapping → **Settings › Responsible gambling**. Deep link `betbook://settings/responsible`.

| Case | English | Danish |
|---|---|---|
| Approaching (80%) | **Title** You've used 80% of your deposit limit<br>**Body** 4.000 kr of 5.000 kr this month. Your limit is in Settings if you want to adjust it. | **Title** Du har brugt 80% af din indbetalingsgrænse<br>**Body** 4.000 kr af 5.000 kr denne måned. Din grænse ligger i Indstillinger, hvis du vil ændre den. |
| Reached (100%) | **Title** You've reached your deposit limit<br>**Body** 5.000 kr of 5.000 kr this month. Take a break or adjust your limit — both are in Settings. | **Title** Du har nået din indbetalingsgrænse<br>**Body** 5.000 kr af 5.000 kr denne måned. Tag en pause eller ændr din grænse — begge findes i Indstillinger. |
| Net-loss alert | **Title** Your net loss passed 3.000 kr<br>**Body** That's the alert you set. Tap to review your limits. | **Title** Dit nettotab er over 3.000 kr | Det er den grænse, du har sat. Tryk for at se dine grænser. |

Rules: state the number, name the tool, offer the two honest options (pause / adjust). Never "Stop now", never "Careful!", never a warning triangle glyph, never red-alert framing — the notification icon is the app's monochrome suit mark in both cases. The word *"grænse"* is always framed as **the user's own** ("din grænse", "the alert you set"), because it is.

---

## 4. In-app surfaces

### 4.1 Weekly summary card (Dashboard, dismissible)

Sits **above** the hero P/L for 48 h after the summary fires (or after the first app open following it), then removes itself.

- Container `surfaceContainerLowest` (light) / `surfaceContainer` (dark), 1 dp `outlineVariant`, `radius.card`, padding 16.
- Line 1: `labelMedium onSurfaceVariant` *"Sidste uge"*. Trailing 40 dp `close` icon button in `onSurfaceVariant` (the dismiss).
- Line 2: trend icon 22 + figure at **36** (`headlineLarge`, tabular) + `kr` — money colour applies (this is a net figure), with sign and trend icon per the standard rule. Uses the standard count-up on first appearance (`MOTION_HANDOFF.md` §5), as a secondary figure: 280 ms, not the hero's 400.
- Line 3: `bodyMedium onSurfaceVariant` — the same sentence as the notification body, minus the "tap" clause.
- Line 4: `Se ugen` / `See the week` text button in `primary` → Stats with range = last week.
- **States**: present · dismissed (gone until next week) · no-activity variant (figure replaced by `bodyLarge` *"Ingen posteringer sidste uge."*, no trend icon, no colour) · absent (default).
- Dismissal is remembered per week (`summaryCardDismissedWeekIso`); it never returns for that week, including after reinstall-free upgrades.

### 4.2 Limit banner (Dashboard, persistent)

Sits above the hero figure (and above the weekly card if both are present — a state outranks a message). Full width, `radius.card`, padding 14, min height 64.

| Variant | Container | Ink | Icon | Progress track |
|---|---|---|---|---|
| **Approaching** (≥ 80%) | `rg.approach.fill` `#E3E2E6` / `#34353A` | `#1A1B20` / `#E3E2E6` | `info_outline` 22 in `onSurfaceVariant` | 6 dp, track `#C4C6D0` / `#44474F`, fill `rg.track.warn` |
| **Reached** (≥ 100%) | `lossContainer` `#FFDBCF` / `#7A2A0E` | `onLossContainer` `#3B0B00` / `#FFDBCF` | `flag_outlined` 22 in the same ink | 6 dp, full, fill `rg.track.reached` |
| **Net-loss** | same as Reached | same | `trending_down` 22 | no track (there is no ratio to show) |

Contents: icon + a two-line block — `titleSmall` label (*"80% af din grænse brugt"* / *"Din grænse er nået"*) and `bodySmall` figure line (*"4.000 kr af 5.000 kr denne måned"*, tabular) — the progress track beneath, and a trailing `Justér` / `Adjust` text button opening Responsible gambling.

**Not dismissible.** It disappears when the condition stops being true (new period, or the user raises the limit). No close button, so no "why did my limit warning vanish" support question.

**Colour note.** The progress track is the one place a `loss`-family colour appears on something that is not a net figure. It is deliberate and bounded: `rg.track.warn` `#8A6D1F` / `#DFC169` at 80–99%, `rg.track.reached` = `color.loss` `#B3401A` / `#FFB59A` at 100%+. It is a limit state, not a judgement of an amount — and individual deposits in lists stay `onSurface`, unchanged. The state is also carried by the icon, the label text and the track's fill fraction, so colour is never alone.

### 4.3 Reduced motion

| Surface | Motion | Reduced |
|---|---|---|
| Weekly card appears | 150 ms fade in `easeOutCubic`; figure count-up 280 ms | both instant, final value |
| Weekly card dismiss | 150 ms fade out, then the layout closes the gap over 150 ms | removed instantly, no gap animation |
| Limit banner appears / changes variant | 180 ms cross-fade of container + ink | instant swap |
| Progress track | fills 220 ms `easeOutCubic` on first paint only | drawn at final width |
| Rationale sheet | standard sheet transition, 260 ms | instant |
| Haptics | none | — |

---

## 5. Take a break

Worth having, and worth being honest about its limits. It is **not** self-exclusion: BetBook cannot stop anyone from depositing anywhere, and a feature that implied it could would be the most harmful thing in the app. So it is scoped to what the app actually controls.

**Settings › Responsible gambling › Tag en pause**, and reachable from the limit banner's `Justér` screen. A pushed route with three choices — *24 timer* · *1 uge* · *1 måned* — as `radius.card` option tiles (`primaryContainer` when selected), plus a plain description of exactly what happens:

- **Totals are hidden**: hero P/L, per-site nets, Stats figures and chart values render as `—` in `onSurfaceVariant`, with a single `Vis totaler` / `Show totals` text button on Dashboard to reveal them for the current session. Transactions themselves are never hidden — the ledger stays readable; only the running scores rest.
- **Reminders pause**: no weekly summary, no limit warnings, for the duration.
- **Logging still works**, unchanged. Pausing the app's scoring must never stop someone recording reality.
- The break ends on its own; a `Afslut pause` / `End break` row is always available, with no friction and no confirmation dialog. Making it hard to leave would be a dark pattern pointed in a nice direction, and it would still be a dark pattern.

While a break is active, Dashboard shows a calm one-line state at the top: *"Pause indtil 17. aug"* / *"Break until 17 Aug"*, `bodyMedium onSurfaceVariant`, with `Afslut` / `End` as a text button. No countdown, no timer, no progress ring.

---

## 6. New tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `rg.approach.fill` | `#E3E2E6` (`neutralContainer`) | `#34353A` | approaching banner container |
| `rg.approach.ink` | `#1A1B20` | `#E3E2E6` | its label + figure line (13.1:1 / 11.6:1) |
| `rg.reached.fill` | `#FFDBCF` (`lossContainer`) | `#7A2A0E` | reached / net-loss banner container |
| `rg.reached.ink` | `#3B0B00` (`onLossContainer`) | `#FFDBCF` | 12.4:1 / 7.9:1 |
| `rg.track.bg` | `#C4C6D0` | `#44474F` | 6 dp progress track, radius 3 |
| `rg.track.warn` | `#8A6D1F` | `#DFC169` | 80–99% fill |
| `rg.track.reached` | `#B3401A` (`color.loss`) | `#FFB59A` | 100%+ fill |
| `notif.icon` | `#FFFFFF` on `#3B5F9E` | same asset | monochrome suit mark, 24 dp, both channels |

No other new colours. The weekly card, sheets, switches, buttons and Settings rows all use existing tokens.

---

## 7. Localisation

| Key | English | Danish |
|---|---|---|
| `reminders` | Reminders | Påmindelser |
| `weeklySummary` | Weekly summary | Ugentligt overblik |
| `weeklySummarySub` | Every Monday at 09:00 | Hver mandag kl. 09.00 |
| `limitWarnings` | Limit warnings | Advarsler om grænser |
| `limitWarningsSub` | At 80% and 100% of your deposit limit | Ved 80% og 100% af din indbetalingsgrænse |
| `setLimitFirst` | Set a limit first | Sæt en grænse først |
| `notifRationaleTitle` | Reminders on your phone | Påmindelser på din telefon |
| `notifRationaleBody` | BetBook creates reminders on your phone. Nothing is sent to a server, and there is no account. | BetBook laver påmindelserne på din telefon. Intet sendes til en server, og der er ingen konto. |
| `notNow` / `continueLabel` | Not now / Continue | Ikke nu / Fortsæt |
| `notifDisabledSystem` | Reminders are turned off in system settings. | Påmindelser er slået fra i systemindstillinger. |
| `openSettings` | Open settings | Åbn indstillinger |
| `lastWeek` | Last week | Sidste uge |
| `seeTheWeek` | See the week | Se ugen |
| `noEntriesLastWeek` | No entries last week. | Ingen posteringer sidste uge. |
| `limitUsedPct` | {pct}% of your limit used | {pct}% af din grænse brugt |
| `limitReached` | You've reached your limit | Din grænse er nået |
| `limitFigureLine` | {used} of {limit} this {period} | {used} af {limit} denne {period} |
| `adjust` | Adjust | Justér |
| `takeABreak` | Take a break | Tag en pause |
| `takeABreakSub` | Hide totals and pause reminders | Skjul totaler og pause påmindelser |
| `breakUntil` | Break until {date} | Pause indtil {date} |
| `endBreak` | End break | Afslut pause |
| `showTotals` | Show totals | Vis totaler |

Sizing consequences: `Advarsler om grænser` and its subtitle are the longest Settings pair in the app — the row's label wraps to two lines rather than ellipsising, and the `Switch` never shrinks. `Ved 80% og 100% af din indbetalingsgrænse` is +34% over English and must be allowed **three** lines at `textScaleFactor 1.3`. Notification titles are truncated by the OS at ~40 characters, so every Danish title above is written to carry its meaning in the first 35: *"Du har nået din indbetalingsgrænse"* (34).

---

## 8. Implementation notes

- One notification plugin, two channels (§3), created on first enable. No channel groups.
- Scheduling: weekly summary as a single repeating inexact weekly alarm; limit warnings are **not** scheduled — they are fired synchronously from the RG evaluation on transaction commit and app resume.
- All content is composed from `RgStatus` and the local store at fire time. Never pre-render a body and store it; a stale figure in a notification is worse than no notification.
- Cancel and reschedule the weekly alarm on: locale change, base-currency change, switch off/on. Cancel everything on "Take a break" and on `Clear all data`.
- `notifiedApproaching` / `notifiedReached` / `notifiedNetLoss` are keyed by period start (`YYYY-MM-DD` of the period's first day) so period rollover clears them without a migration or a cron.
- Deep links resolve through the existing route table; both destinations already exist. Tapping a notification on a cold start must land on the destination, not on Dashboard-then-jump.
- `POST_NOTIFICATIONS` is the only new permission. No exact alarms, no boot receiver beyond the plugin's own rescheduling, no foreground service.
