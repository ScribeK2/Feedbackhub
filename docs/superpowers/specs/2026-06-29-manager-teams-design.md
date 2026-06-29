---
name: manager-teams-and-scoped-feedback
description: Manager role with a configurable CSR team, team-scoped feedback views, and a daily digest email
status: draft
created: 2026-06-29T12:33:10Z
updated: 2026-06-29T12:33:10Z
---

# Manager Teams & Team-Scoped Feedback

## Summary

Introduce a **manager** role. A manager configures a **team** — a list of CSR
names — and as a result (1) sees only feedback for their team's CSRs on the home
page and feedback pages, and (2) receives a **daily digest email** of new feedback
submitted for those CSRs.

CSRs remain **free-text names**, exactly as today: `FeedbackSubmission.csr_name`
is a string extracted from the submission form's `data["csr"]`. There is no CSR
account or CSR table. A manager's "team" is a manager-owned list of CSR name
strings matched against `csr_name`.

## Locked Decisions

1. **CSR identity** — free-text CSR name strings, matched against
   `feedback_submissions.csr_name`. No CSR records.
2. **Role** — add `"manager"` as a third `User.role` value, assigned by an admin
   via the existing `Admin::Users` screen.
3. **View scope** — only managers are filtered (to their team). Admins and regular
   users keep the current global view. A manager with an **empty team** falls back
   to the global view (view layer only — see §5).
4. **Notifications** — **daily digest** at a fixed time, listing feedback submitted
   for the team's CSRs since the last digest. Managers with no new feedback are
   skipped. (Not per-feedback email.)
5. **Realtime** — per-manager Turbo Stream channels so the live feed stays
   correctly filtered (see §6).
6. **Recent activity for managers** — feedback-only, scoped to the team; Articles
   and Updates are hidden for managers with a non-empty team.

## Data Model

### `User`
- `role` validation becomes `inclusion: { in: %w[admin user manager] }`.
- Add `manager?` helper (`role == "manager"`).
- Add `has_many :team_memberships, foreign_key: :manager_id, dependent: :destroy`.
- Add `team_csr_names` → `team_memberships.pluck(:csr_name)`.
- New column `last_digest_sent_at:datetime` (nullable) — digest watermark.

### `TeamMembership` (new)
```
manager_id  :integer  not null, FK -> users
csr_name    :string   not null
timestamps
```
- `belongs_to :manager, class_name: "User"`
- Validations: `csr_name` presence; uniqueness scoped to `manager_id`
  (case-insensitive — see §4).
- Index: unique `[manager_id, csr_name]`.

### Migrations
- `add_column :users, :last_digest_sent_at, :datetime`
- `create_table :team_memberships` with FK to users and the unique index.

Both are additive/reversible. No existing data is touched or backfilled.

## Components & Files

### Team configuration UI — `/team`
- **Routes**:
  ```ruby
  get "team", to: "team_memberships#index"
  resources :team_memberships, only: [:create, :destroy]
  ```
  `/team` is the friendly page path; create/destroy manage individual CSR rows.
- **`TeamMembershipsController`** — gated by a `require_manager` before_action
  (mirrors `require_admin`). Actions:
  - `index` — renders the team page.
  - `create` — adds a `TeamMembership` for `current_user` from a `csr_name` param.
  - `destroy` — removes one of `current_user`'s memberships.
- **Phlex views** (follow existing `app/views/components/**` patterns):
  - A "Team list" box listing current CSRs, each with a **Remove** button (DELETE).
  - An **Add team member** button that reveals a text field + **Save** (POST).
  - The text field is backed by a **`<datalist>`** populated with the distinct
    existing `csr_name` values (`FeedbackSubmission.distinct.pluck(:csr_name)`),
    giving typo-resistance while staying free-text and working for CSRs that have
    no feedback yet.
- **Nav**: a `/team` link shown only when `current_user&.manager?`.

### Authorization
- Add `require_manager` to `ApplicationController` alongside `require_admin`.

## Feedback Scoping (§ home + feedback index)

### Scope
- `FeedbackSubmission.for_csrs(names)` — case-insensitive match:
  `where("LOWER(csr_name) IN (?)", names.map(&:downcase))`. Empty `names` → an
  empty relation (`none`). SQLite `=`/`IN` on text is case-sensitive, so matching
  is normalized via `LOWER()` on both sides; this same normalization governs the
  digest match and `TeamMembership` uniqueness.

### Controller behavior
- A shared helper (e.g. `team_scoped(relation)` in `ApplicationController`):
  - manager **with** a non-empty team → `relation.for_csrs(current_user.team_csr_names)`
  - otherwise (admin, user, or empty-team manager) → `relation` unchanged.
- **`FeedbackController#index`**: the team scope is the **base relation**; the
  existing `?csr=`, `?submitted_by=`, `?q=` params narrow *within* it and can
  never widen it. `?csr=OffTeamName` therefore returns nothing for a managed
  scope.
- **`HubController#index`**:
  - Metric counts (`high/medium/low/total`) computed from the team-scoped relation
    for managers.
  - `recent_activity`: for a manager with a non-empty team, build the list from
    **team-scoped feedback only** (no Articles/Updates). For everyone else
    (incl. empty-team managers), keep the current mixed feed.

## Empty-Team Fallback (the trap to avoid)

"Empty team → see everything" is a **view-layer** convenience only, implemented by
the controller helper returning the unscoped relation. The **digest must not** use
this fallback: it queries `for_csrs(team)` directly, so an empty team yields an
empty set and the manager is skipped. An empty team must never produce a digest of
all feedback in the system.

## Realtime (Turbo Streams)

`FeedbackSubmission#broadcast_updates` currently prepends to global channels
(`"feedback_submissions"`, `"dashboard"`), which would push off-team cards live to
a manager's open page and visibly break the filter.

- Compute **`managers_for(csr_name)`** — managers whose team includes the
  submission's `csr_name` (case-insensitive). This is the **same query the digest
  needs**, so it lives in one place (e.g. a `TeamMembership.managers_for(csr_name)`
  scope / `User` class method).
- Broadcasting:
  - Keep the **global** channel broadcast for admins/regular users.
  - Additionally broadcast the feedback card + dashboard fragments to a
    **per-manager channel** (e.g. `"dashboard:#{manager.id}"` /
    `"feedback_submissions:#{manager.id}"`) for each manager in
    `managers_for(csr_name)`.
- Subscriptions:
  - Admin/user pages subscribe to the global channels (as today).
  - **Manager pages with a non-empty team** subscribe to their **per-manager
    channels only**, so they receive live updates exclusively for their team.
  - Empty-team manager pages subscribe to the global channels (consistent with the
    view fallback).

## Daily Digest

- **Mailer**: `ManagerDigestMailer#daily(manager, submissions)` with a Phlex/ERB
  template summarizing the new feedback (CSR, priority, type, submitted_by,
  ticket, timestamp, link to the submission).
- **Job**: `DailyDigestJob` (ActiveJob → Solid Queue) iterates
  `User.where(role: "manager")`; for each:
  - `new = FeedbackSubmission.for_csrs(manager.team_csr_names)
           .where("created_at > ?", manager.last_digest_sent_at || manager.created_at)`
  - if `new.empty?` → skip.
  - else deliver the digest, then update `manager.last_digest_sent_at = Time.current`.
- **Schedule**: add to `config/recurring.yml` under `production:`, fixed time
  (e.g. `schedule: at 8am every day`).
- **SMTP**: host/port/credentials read from Rails credentials / ENV (not
  hardcoded). `ApplicationMailer` default `from` set to a configurable address.
  Delivery via background job (already async through the recurring job). Actual
  SMTP settings supplied at deploy time; `config/environments/production.rb`
  `action_mailer` config reads from ENV/credentials.

## Admin UI touch-up

`Admin::UserFormComponent` role `<select>` currently lists `%w[user admin]`. Add
`manager` so admins can assign the role. `user_params` already passes `role`
through, and the `User` validation will accept the new value.

## Error Handling

- Adding a duplicate CSR to a team → uniqueness validation; surface a friendly
  "already on your team" message, no crash.
- Blank CSR name on add → presence validation; re-render with error.
- `require_manager` redirect for non-managers hitting `/team` (mirror
  `require_admin`).
- Digest job: a delivery failure for one manager must not abort the run; rescue
  per-manager, log, and continue. `last_digest_sent_at` is updated only on
  successful enqueue/delivery so failed managers retry next run.

## Testing

- **Model**: `TeamMembership` validations (presence, case-insensitive uniqueness
  per manager); `User#manager?`, `User#team_csr_names`; `FeedbackSubmission.for_csrs`
  (case-insensitivity, empty → none).
- **Controller/Request**:
  - `TeamMembershipsController` create/destroy/index, manager gate.
  - `FeedbackController#index` scoping: manager sees only team feedback;
    `?csr=OffTeamName` returns nothing; empty-team manager sees all; admin/user
    unaffected.
  - `HubController#index`: team-scoped counts and feedback-only recent activity
    for managers; mixed feed for others.
- **Mailer**: `ManagerDigestMailer#daily` renders expected submissions.
- **Job**: `DailyDigestJob` selects only since-watermark feedback, skips empty
  teams (and empty-team managers — no firehose), updates watermark, isolates
  per-manager failures.
- **Realtime**: a submission for a CSR on manager A's team broadcasts to A's
  per-manager channel and the global channel, but not to manager B's channel.

## Out of Scope (YAGNI)

- Per-manager digest time or weekly cadence (fixed daily only).
- Per-feedback/real-time email.
- CSR accounts, a CSR table, or backfilling existing string data.
- Scoping Articles/Updates by anything (they have no CSR).
- Two managers sharing a CSR is allowed and needs no special handling.
