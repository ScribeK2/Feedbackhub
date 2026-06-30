---
name: csr-scorecards
description: Per-CSR performance scorecards for managers — issue trends and breakdowns for 1-on-1s
status: draft
created: 2026-06-30T13:11:19Z
updated: 2026-06-30T13:11:19Z
---

# CSR Scorecards

## Summary

A **Scorecard** gives a manager a per-CSR view of the feedback (issues) logged against
that CSR over a chosen time range, so they can walk through progress and recurring
problems in a 1-on-1. It is a read-only dashboard built entirely from existing
`FeedbackSubmission` data — no new feedback fields, no new tables.

## Problem & framing

Every `FeedbackSubmission` in FeedbackHub is a **negative signal**: it records an issue
with a CSR (a `feedback_type`, an `impact`, and a `priority`). The system has **no record
of total tickets handled**, so there is no fair denominator for a literal numeric "score."

Consequently the scorecard is **not a grade**. It is a qualitative dashboard of *issue
trends and breakdowns*:

- "Progress" = fewer / lighter issues over time.
- "Continuing issues" = categories that keep recurring.

A single computed score from negative-only, denominator-free data would mislead and feel
punitive, so we deliberately do not produce one.

## Scope

### In scope
- A `ScorecardReport` aggregation object.
- A `ScorecardsController` with `index` (team tiles) and `show` (one CSR).
- Phlex components for the index and detail views.
- A "Scorecards" nav entry for managers and admins.

### Out of scope / non-goals
- **CSR identity normalization.** `csr_name` is a free-text string. "John Smith",
  "John S", and "j smith" are *different* scorecards and will each show only partial
  history. We do not solve identity matching in this feature; matching stays exactly as
  the rest of the app does it (case-insensitive equality via `FeedbackSubmission.for_csrs`).
  This is a documented known limitation.
- No new feedback fields, no ticket-volume capture, no snapshot/rollup tables.
- No interactive/JS charting library.

## Authorization

Enforced **server-side in the controller**, not merely by which tiles the index renders
(a manager can hand-type a `?csr=` value):

- A **manager** may view a scorecard only for a CSR on their team
  (`current_user.team_csr_names`, case-insensitive). `show` rejects any other `?csr=`
  with a 404 / redirect. This preserves the existing "scope can't be widened" invariant.
- An **empty-team manager sees no scorecards.** This mirrors the daily digest's deliberate
  *no-global-fallback* behavior — NOT the feedback view's "empty team = global view"
  fallback. Showing scorecards for people not on your team is meaningless for 1-on-1s.
- **Admins** may view any CSR's scorecard.
- Unauthenticated users are redirected by the existing `require_authentication`.

## Routing

CSR names contain spaces and dots (`j.smith` would trip Rails' path-format parsing), so
the CSR is passed as a **query parameter**, matching the existing `?csr=` filter convention:

- `GET /scorecards` → `ScorecardsController#index` (tiles for the viewer's CSRs)
- `GET /scorecards/show?csr=John+Smith` → `ScorecardsController#show` (one CSR's detail)

## Architecture

### `ScorecardReport` (PORO — the only unit with real logic)

Lives in `app/models/scorecard_report.rb` (plain Ruby value object; not an AR model).

**Input:** `csr_name:` and `date_range:` (a `Range` of dates/times; default last 30 days).

**Behavior:**
- Builds its base relation from `FeedbackSubmission.for_csrs(csr_name)` — never a new
  matcher — so case-insensitive matching is identical to the rest of the app.
- Computes, for the selected range and for the **equal-length immediately-preceding
  window** ("previous period"):
  - total issue count + delta vs previous period;
  - per-bucket counts for the trend (weekly buckets for ranges ≤ ~3 months, monthly
    beyond);
  - group counts by `priority`, by `feedback_type`, by `impact`;
  - the most recent ~5 submissions.

**Output:** an immutable value object exposing those figures. No view or controller does
its own aggregation.

### `ScorecardsController`

- `index` — gathers the viewer's CSR list (`current_user.team_csr_names`, or all CSRs for
  admins) and a lightweight per-CSR period count + trend arrow; renders
  `Scorecards::IndexComponent`. Empty-team managers get the "add CSRs to your team" prompt
  (reusing the team-page copy pattern), not a global list.
- `show` — authorizes `params[:csr]` against the viewer (see Authorization), builds a
  `ScorecardReport`, renders `Scorecards::ShowComponent`. Reads an optional date range
  from params; defaults to last 30 days.

### Phlex components

Modeled on `Team::IndexComponent` and `Dashboard::MetricCard*`:

- `Scorecards::IndexComponent` — grid of CSR tiles (name, period issue count, trend arrow);
  each links to the detail page. Empty-team prompt when applicable.
- `Scorecards::ShowComponent` — header (CSR name + date-range control), then the four panels.

## The four panels (detail page)

All derived from existing columns (`priority`, `feedback_type`, `impact`, `created_at`):

1. **Issue volume + trend** — headline count for the period, a `▲/▼ vs previous period`
   delta, and a trend visual rendered as **inline-SVG bars, one per time bucket**
   (weekly ≤ ~3 months, monthly beyond). No interactive charting.
2. **Severity mix** — counts by `priority` (High / Medium / Low) as labeled CSS bars, with
   the High-priority delta called out.
3. **Category breakdown** — counts by `feedback_type` (Invalid Ticket / Knowledge Gap /
   Process Failure / Other), sorted descending. The core coaching panel — shows *what*
   recurs.
4. **Impact breakdown + recent issues** — counts by `impact` (Resolution Time / Client
   Experience / Team Workload / Other), plus the latest ~5 submissions (date, type,
   priority) each linking to the existing `feedback#show` page.

## Date range & "previous period"

- The detail page has a date-range control; default range is **the last 30 days**.
- "Previous period" is the **equal-length window immediately preceding** the selected
  range (a 30-day range compares against the 30 days before it). This is well-defined for
  any custom range.

## Empty / zero states

Three visually distinct states (negative-only data makes this easy to get backwards):

- **Zero issues in period** — the *good* case. Renders as a positive/neutral empty state
  (e.g. "No issues logged 🎉"), with the trend/panels showing zero.
- **No feedback on record at all** for this CSR — a plain "no data yet" state.
- **Not on your team** — never rendered; `show` returns 404 / redirect before the view.

## Navigation

Add a **"Scorecards"** item to the manager/admin navigation, alongside "My Team".

## Testing (real tests, no mocks)

**`ScorecardReport` unit tests:**
- case-insensitive name matching (reuses `for_csrs`);
- date-bucket boundary correctness (submissions on range edges land in the right bucket);
- previous-period delta math (incl. previous period = 0);
- empty result and zero-issue result.

**`ScorecardsController` tests:**
- manager can view an own-team CSR;
- manager is **denied (404/redirect)** a non-team `?csr=`;
- empty-team manager sees no scorecards (index prompt; `show` denied);
- admin can view any CSR;
- unauthenticated user redirected.

**Component render smoke tests:**
- index renders tiles and the empty-team prompt;
- show renders all four panels and the zero-issue empty state.

## Files (anticipated)

- `app/models/scorecard_report.rb` (new)
- `app/controllers/scorecards_controller.rb` (new)
- `app/views/components/scorecards/index_component.rb` (new)
- `app/views/components/scorecards/show_component.rb` (new)
- `config/routes.rb` (add the two routes)
- navigation component (add "Scorecards" link)
- tests for the report, controller, and components
