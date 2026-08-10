# Claude Design brief — BetBook: weekly summary & limit-warning notifications

Paste everything below into Claude Design. It **extends the existing BetBook
design system** — do not restyle the app. Reference the latest handoff
`docs/design/from-claude-design-v3/DESIGN_HANDOFF.md` and `.../MOTION_HANDOFF.md`
(tokens, ColorSchemes, `MoneyColors`, Manrope) and `.../mockups/`.

---

## Context

BetBook is a calm, **offline** ledger for betting deposits/withdrawals — **"a
ledger, not a casino,"** with a strong responsible-gambling stance. It already
has:
- A **base-currency net P/L** across all sites.
- **Responsible-gambling limits** the user can enable in Settings › Responsible
  gambling: a **deposit limit** (an amount per **day / week / month**) and a
  **net-loss alert**. Live status (`RgStatus`) already knows
  `periodDepositBase`, `depositLimitBase`, `depositLimitExceeded`, and
  `netLossExceeded` — but today that status is only surfaced *inside* the app.

The app is privacy-first and local-only; the only network use is an optional
weekly FX-rate refresh. Notifications would be **local/scheduled**, generated
on-device — no server, no account, no data leaves the phone.

## Goal

Design two calm, opt-in **notification** experiences plus their in-app
surfaces:
1. **Weekly summary** — a once-a-week local notification with the week's P/L and
   a one-line takeaway, tapping through to Stats.
2. **Limit warnings** — a notification when the user is **approaching** or **has
   reached** their deposit limit (and/or the net-loss alert), reinforcing the
   responsible-gambling tools rather than nagging.

Design must cover: the **in-app settings** to enable/configure these, the
**notification content/copy** (both are user-facing and localised), and any
**in-app surface** (e.g. a summary card or a limit banner) that pairs with them.

## Open design decisions — please decide and justify briefly

1. **Weekly summary timing**: fixed (e.g. Monday 09:00) vs. user-chosen day/time.
   Recommend the simplest that still feels considerate.
2. **Limit-warning thresholds**: at what fraction of the deposit limit does the
   "approaching" warning fire (e.g. 80%)? One warning per period or escalating?
   How to avoid alarm fatigue.
3. **Tone for a bad week**: the weekly summary must state a loss **calmly and
   supportively** — never sympathetic-dramatic, never congratulatory on a win.
   Provide the copy for win / loss / break-even, in English + Danish.
4. **In-app pairing**: does a limit warning also show as an in-app banner/state
   on Dashboard when the app is opened, or only as a system notification? Design
   whichever you recommend.

## Scope — specify each, with light + dark values and reduced-motion fallbacks

1. **Settings additions** (under Responsible gambling and/or Settings › Data):
   toggles for "Weekly summary" and "Limit warnings," any schedule picker, and
   the **permission-request** moment (Android 13+ needs runtime notification
   permission). Show the pre-permission rationale and the denied/blocked state
   (deep-link to system settings). Keep the switch rows consistent with existing
   Settings rows.
2. **Notification content** for each type: title, body, and the tapped
   destination (weekly → Stats card; limit → Responsible-gambling screen).
   Provide exact copy for all states in **English + Danish**. No emoji-as-alarm,
   no red-alert framing.
3. **Weekly-summary in-app surface** (if you recommend one): e.g. a dismissible
   summary card at the top of Dashboard for the current week, using the existing
   hero-figure and count-up styling. Define its states and dismissal.
4. **Limit-warning in-app state**: how "approaching" vs "reached" look — likely
   a calm banner using `MoneyColors` loss/neutral, an icon, and a link to adjust
   the limit. This must not look like a punishment; it is a tool.
5. **A "self-exclusion / take a break" affordance?** Optional — if you think the
   responsible-gambling posture warrants a gentle "pause logging / hide totals"
   option reachable from a limit warning, propose it. Skip if it overreaches.

## Non-negotiables

- **Calm over casino, and responsible-gambling-first.** Never gamify limits, never
  celebrate deposits or wins, never shame losses. The warnings exist to help the
  user, framed supportively.
- **Opt-in only.** Nothing notifies until the user enables it and grants OS
  permission. Respect a denied permission gracefully.
- Reuse existing tokens (ColorSchemes, `MoneyColors`, radii, spacing, Manrope);
  any new token in hex for **both** themes.
- Profit/loss colour only on net figures, always with sign + trend icon.
- **Reduced motion**: banners/cards appear without motion when
  `MediaQuery.disableAnimations` is set.
- **Localised** English + Danish for every string, including notification copy;
  Danish runs longer — don't clip.
- Privacy: all notification content is generated on-device; say nothing that
  implies cloud/account.

## Dev notes (context for feasibility — not design constraints)

- Implemented with a local-notifications plugin + on-device scheduling; a new
  `POST_NOTIFICATIONS` permission and possibly exact-alarm handling will be
  added. The design should assume **local, scheduled** notifications only.
- Deposit-limit period is day/week/month; `RgStatus` already computes current
  period deposits vs limit and the net-loss flag.

## Deliverables

1. **Mockups** (light + dark) of: the new Settings rows + permission rationale,
   both notification types (system-notification mockups with real copy), the
   weekly-summary in-app card, and the limit-warning banner (approaching +
   reached).
2. A **design-handoff markdown** (same structure as `DESIGN_HANDOFF.md`):
   component specs, new tokens (hex, both themes), all copy for both languages,
   states, thresholds/schedule recommendations, and reduced-motion +
   permission-flow notes. Make it self-contained — this is what I implement from.
