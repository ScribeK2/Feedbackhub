# Feedback Comments, Subscriptions & Notifications — Design

- **Created:** 2026-07-06T11:40:19Z
- **Status:** approved (autonomous goal session)

## Goal

Let users leave comments on feedback submissions. Notify interested users when a
comment lands, both in-app (navbar bell) and by email. The submitter of a feedback
is auto-subscribed; managers whose team includes the feedback's CSR are implicitly
subscribed. Users can unsubscribe per-feedback, with a management page under user
settings.

## Context / constraints

- `feedback_submissions.submitted_by` is a free-text form field, not a user FK.
  All routes require login, so the actual submitting account is `current_user` at
  create time — we add a real `submitter_id` FK for subscriptions.
- Managers are linked to CSRs by name via `TeamMembership` (`User.managers_for`).
  Membership changes over time, so manager interest is computed at comment time,
  not materialized at submission time.
- Submissions are displayed in pre-rendered `<dialog>` modals
  (`Hub::SubmissionModalComponent`) on hub/feedback index pages, and standalone at
  `GET /feedback/:id`.
- SMTP + `deliver_later` (Solid Queue) already work (`ManagerDigestMailer`).
- Realtime uses Turbo Streams broadcasts (`turbo_stream_from` per-user streams).

## Data model

### `feedback_submissions.submitter_id` (new column)
Nullable integer FK → users (existing rows have no submitter). Set from
`current_user` in `FeedbackController#create`.

### `comments`
- `feedback_submission_id` FK, null: false
- `author_id` FK → users, null: false
- `body` text, null: false (plain text, rendered with `simple_format`-style line breaks)

### `feedback_subscriptions`
- `feedback_submission_id` FK, `user_id` FK, both null: false
- `subscribed` boolean, null: false, default: true
- Unique index on `[feedback_submission_id, user_id]`

Semantics: a row with `subscribed: true` is an **explicit subscription**; a row
with `subscribed: false` is an **explicit opt-out** (mute). No row means: default
behavior (submitter/commenters get rows automatically; managers are implicit).

### `notifications`
- `user_id` FK, `comment_id` FK, both null: false
- `read_at` datetime, nullable
- Index on `[user_id, read_at]`, unique index on `[user_id, comment_id]`

## Who gets notified

`FeedbackSubmission#notification_recipients(except:)`:

```
(users with subscription subscribed: true  ∪  User.managers_for(csr_name))
  −  users with subscription subscribed: false
  −  [comment author]
```

Rules:
- Submitter gets a `subscribed: true` row via `after_create` on the submission
  (when `submitter` present).
- A commenter gets a `subscribed: true` row when they comment — but only if no
  row exists yet. An explicit opt-out is sticky; commenting does not re-subscribe.
- Managers are included dynamically so team changes are respected. A manager who
  mutes a feedback gets a `subscribed: false` row and drops out.

## Notification delivery

`Comment` `after_create_commit`:
1. Auto-subscribe author (`find_or_create_by`, see stickiness rule).
2. For each recipient: create a `Notification` row, broadcast to the user's
   `notifications:<user_id>` stream (prepend item into bell dropdown list +
   replace unread badge), and `CommentMailer.new_comment(recipient, self).deliver_later`.
3. Broadcast-append the comment to `feedback_submission_comments:<submission_id>`
   so open comment sections update live (the create response only resets the form;
   the list update comes via the broadcast, matching the app's realtime patterns).

Both channels always fire (in-app + email); no per-channel preference in v1.

## Routes & controllers

```ruby
resources :feedback, only: [...] do
  resources :comments, only: [ :index, :create ]
  resource :subscription, only: [ :update ]   # PATCH toggle subscribed=true/false
end
resources :notifications, only: [ :index, :show ] do
  collection { post :mark_all_read }
end
get "settings/subscriptions", to: "settings#subscriptions"
```

- `CommentsController#index` renders the comments section (list + form +
  subscribe/unsubscribe toggle) for a lazy Turbo Frame.
- `CommentsController#create` responds with a turbo_stream that resets the form.
- `SubscriptionsController#update` upserts the row with the requested `subscribed`
  value; responds turbo_stream (toggle swap) or redirects back (settings page).
- `NotificationsController#show` marks the notification read and redirects to the
  feedback (`feedback_path`), matching how search results link to submissions.
- `#mark_all_read` clears the badge.
- `SettingsController#subscriptions` lists the user's `subscribed: true` rows with
  unsubscribe buttons. Managers' implicit subscriptions are muted from the feedback
  modal itself (toggle in the comments section), not listed here.

Authorization: any signed-in user can view/comment on any feedback (matches
existing `FeedbackController#show`, which does not team-scope).

## UI

- **Comments in the modal:** `Hub::SubmissionModalComponent` gains a comments
  section as a `turbo_frame` with `src: feedback_comments_path(...)`,
  `loading: :lazy` — loads only when the dialog opens (frame becomes visible).
- **Navbar bell:** between theme toggle and user menu. Unread-count badge, DaisyUI
  dropdown listing recent notifications ("Alice commented on feedback for Jane
  Doe · 2h ago"), each linking to `notification_path` (mark-read + redirect),
  plus "Mark all read". Wrapped in `turbo_stream_from "notifications:<id>"`.
- **Settings page:** `/settings/subscriptions`, linked from the user dropdown
  menu; lists subscribed feedbacks with Unsubscribe buttons.
- **Email:** subject "New comment on feedback for <csr_name>", body with comment
  text, author, link to the feedback, and a note that subscriptions are managed in
  Settings.

## Alternatives considered

- **Materialize manager subscriptions at submission create** — rejected: goes
  stale when team membership changes; dynamic computation reuses the existing
  `managers_for` pattern (same approach as broadcast fan-out and the daily digest).
- **Rich-text (Lexxy) comment bodies** — rejected for v1: comments are short;
  plain text avoids per-modal editor weight and XSS surface.
- **Separate `notification_preferences` (email vs in-app)** — deferred: goal says
  "either by email or by some notification"; ship both, add preferences if asked.

## Testing

- Model tests: recipient computation (submitter, commenter, manager-by-CSR,
  opt-out stickiness, author exclusion, case-insensitive CSR match), notification
  + email fan-out on comment create, auto-subscribe behaviors.
- Controller tests: comments index/create, subscription toggle, notifications
  index/show/mark_all_read, settings page, auth required.
- Mailer test: recipients, subject, body links.
