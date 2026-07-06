# FeedbackHub

FeedbackHub is an internal quality-management hub for customer support teams. It gives
supervisors and managers one place to log structured feedback about CSR (customer service
representative) ticket handling, discuss it, and track quality trends per CSR over time —
alongside a lightweight knowledge base of articles, updates, and tools.

## What it does

- **Structured feedback** — Feedback is submitted through admin-defined templates
  (`FeedbackTemplate`), so every entry captures consistent fields such as ticket number,
  CSR, feedback type, impact, and priority. Rich-text details are supported via the
  Lexxy editor. Submissions are searchable and filterable.
- **Comments & notifications** — Each feedback submission has a comment thread with live
  updates (Turbo Streams). Submitters, commenters, and the CSR's managers are notified
  in-app (navbar bell) and by email, with per-submission and account-level unsubscribe.
- **Manager teams** — Managers maintain a roster of the CSRs they supervise, get
  team-scoped feedback views, and receive a daily email digest of their team's feedback.
- **CSR scorecards** — Per-CSR dashboards for managers: feedback volume trends and
  severity/category/impact breakdowns over a chosen date range, compared against the
  preceding period.
- **Knowledge base** — Articles, team updates, tags, and a tools directory, all covered
  by global search.
- **Admin area** — Manage feedback templates and users. Roles: `admin`, `manager`, `user`.

## Tech stack

- **Framework**: Rails 8.1 on Ruby 4.0
- **Views**: [Phlex](https://www.phlex.fun/) components with PhlexyUI (DaisyUI)
- **Frontend**: Turbo, Stimulus, Tailwind CSS
- **Database**: SQLite, with Solid Queue / Solid Cache / Solid Cable
- **Rich text**: Lexxy
- **Testing**: Minitest with parallel execution, Capybara for system tests

## Getting started

```bash
bin/setup            # Install dependencies, prepare the database
bin/rails db:seed    # Create the default admin user and CSR Feedback template
bin/dev              # Start the server with CSS watching (or: bin/rails server)
```

Seeding creates an admin account (`admin@feedbackhub.local` / `password`) and a starter
"CSR Feedback" template.

### Tests and linting

```bash
rails test           # Run the test suite
rails test:system    # System tests
bin/rubocop          # Style checks (rails-omakase)
```

## Documentation

Detailed docs live in [`/docs/`](docs/overview.md), covering the application
architecture, the Phlex view layer and component patterns, Tailwind/DaisyUI usage, and
the Phlex scaffold generator.
