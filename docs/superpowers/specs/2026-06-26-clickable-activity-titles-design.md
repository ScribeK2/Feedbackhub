---
name: clickable-activity-titles
description: Make each Recent Activity entry's title a link to a relevant destination, per activity type, without adding routes or detail pages.
status: backlog
created: 2026-06-26T16:18:46Z
updated: 2026-06-26T16:18:46Z
---

# Clickable Recent Activity Titles — Design Spec

## Summary

On the dashboard's "Recent Activity" feed, entries are currently not clickable.
Make each entry's **title** (the bold first line) a link to a relevant destination
based on the entry's type. Single-file, view-only change — no new routes, controllers,
models, or detail pages.

## Scope

- **Change:** `app/views/components/dashboard/activity_item_component.rb` only.
- **Non-goals:** no new routes/controllers/models; no new detail pages; no change to
  the row's existing hover treatment, badge, subtitle, or timestamp; whole-row click is
  out of scope (only the title is the click target, per request).

## Behavior

The title in each `render_*_content` method becomes an anchor (`a`) instead of plain
text. Destinations, computed inside the component from `@type` / `@item`:

| Type       | Destination | Helper |
|------------|-------------|--------|
| `:feedback` | Feedback list, filtered to that submission by ticket number | `feedback_index_path(q: @item.ticket_number)` when `ticket_number` is present; otherwise `feedback_index_path` |
| `:article`  | The article's show page | `article_path(@item)` |
| `:update`   | The Updates list | `updates_path` |

Rationale for the feedback target: `feedback#show` renders a closed `<dialog>` modal
(`Hub::SubmissionModalComponent`) and is blank when visited directly, so it is not a
valid navigation target. The feedback index's `search` scope (`q` param) matches
`ticket_number`, so filtering by ticket surfaces the clicked submission. When a
submission has no ticket number (`ticket_number` blank), fall back to the unfiltered
list.

## Presentation

- The title anchor uses `link link-hover` (DaisyUI) so it shows the primary color and
  underlines on hover — matching the existing link style in the feedback index table
  (`link link-hover link-primary`).
- Keep the title's existing `text-sm font-medium truncate` classes on the anchor so
  layout/truncation is unchanged.
- The row keeps `hover:bg-base-200`; only the title navigates.
- Subtitle (`text-xs` line), type badge, and timestamp are unchanged.

## Edge cases

- **Blank feedback ticket number:** link falls back to `feedback_index_path` (plain
  list). The component already renders "Ticket: —" in this case, so a coarse fallback
  is consistent.
- **Long titles:** `truncate` stays on the anchor; the link text truncates exactly as
  the plain text did.
- The feedback `q` filter uses a LIKE match, so the filtered list shows the target
  submission (and any incidental matches); acceptable for "surface that item."

## Testing

- View-only change; the repo has no view/component unit tests, so verification is:
  `bin/rails test` stays green (controller tests still render the dashboard), and a
  visual check that each activity title renders as a hover-styled link pointing at the
  correct URL.
- The dev database has no activity records (empty seed), so the live feed shows "No
  recent activity." To verify rendering and URLs, exercise `ActivityItemComponent`
  against sample records of each type (e.g. a controller/integration render, or a
  temporary fixture in the test database) and assert the emitted `href` per type —
  rather than relying on the empty dev feed.

## Out of scope / future

- A real standalone feedback detail page (would let feedback link to a precise item
  instead of a filtered list).
- Per-update detail pages / anchoring the Updates list to the specific update.
- Whole-row click targets.
