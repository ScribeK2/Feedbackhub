# Clickable Activity Titles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make each Recent Activity entry's title a link to a relevant destination based on its type.

**Architecture:** Single Phlex view component (`Dashboard::ActivityItemComponent`) renders each title as an `a` anchor instead of a `p`. The href is computed from `@type`/`@item`: feedback → the feedback list filtered by ticket number (fallback to the plain list when blank), article → the article show page, update → the updates list. Verified by an integration test that GETs the dashboard with fixtures and asserts the emitted hrefs inside `#recent_activity`.

**Tech Stack:** Rails 8.1, Phlex 2.4 + PhlexyUI, DaisyUI 5.5.19, Minitest integration tests.

## Global Constraints

- View layer only — change **only** `app/views/components/dashboard/activity_item_component.rb` (plus the test file). No routes, controllers, or models.
- Destinations (exact): feedback → `feedback_index_path(q: @item.ticket_number)` when `ticket_number` present else `feedback_index_path`; article → `article_path(@item)`; update → `updates_path`.
- The title anchor uses the DaisyUI classes `link link-hover` plus `block text-sm font-medium truncate` (keeps the original title sizing/truncation; `block` makes `truncate` work on the anchor).
- Do NOT change the row hover (`hover:bg-base-200`), the type badge, the subtitle line, or the timestamp. Only the title line changes from `p` to `a`.
- `feedback#show` is a modal and renders blank standalone — never link feedback to `feedback_path`.
- The repo has NO view/component unit tests; verification is a real integration test asserting rendered hrefs, plus `bin/rails test` staying green. No cheater tests.
- The classes `link`, `link-hover`, `block`, `truncate` already exist in the built CSS (used by other components), so no Tailwind rebuild is required for this change.
- Route helpers (`feedback_index_path`, `article_path`, `updates_path`) are available inside Phlex components here — existing components call path helpers directly.

---

## Task 1: Make Recent Activity titles clickable

**Files:**
- Modify: `app/views/components/dashboard/activity_item_component.rb` (the three `render_*_content` methods; add one private helper)
- Test: `test/controllers/hub_controller_test.rb` (add integration tests)

**Interfaces:**
- Consumes: existing `ActivityItemComponent#initialize(item:, type:)`; fixtures `feedback_submissions` (`high_priority` ticket `TK-001`, `low_priority` ticket `TK-002`, `simple_submission` with no ticket), `articles` (`dns_guide`, `policy_doc`), `updates` (`pinned_standup`, `archived_standup`); auth helper `sign_in_as_user`.
- Produces: anchors inside `#recent_activity` with hrefs `feedback_index_path(q: ...)` / `feedback_index_path` / `article_path(record)` / `updates_path`, each carrying the `link` class.

- [ ] **Step 1: Write the failing integration tests**

Append these tests inside `class HubControllerTest` in `test/controllers/hub_controller_test.rb` (after the existing tests, before the final `end`):

```ruby
  test "recent activity feedback title links to feedback list filtered by ticket" do
    get hub_path
    assert_select "#recent_activity a[href=?]", feedback_index_path(q: "TK-001")
    assert_select "#recent_activity a[href=?]", feedback_index_path(q: "TK-002")
  end

  test "recent activity feedback without a ticket links to the plain feedback list" do
    # the simple_submission fixture has no ticket_number
    get hub_path
    assert_select "#recent_activity a[href=?]", feedback_index_path
  end

  test "recent activity article title links to the article show page" do
    get hub_path
    assert_select "#recent_activity a[href=?]", article_path(articles(:dns_guide))
    assert_select "#recent_activity a[href=?]", article_path(articles(:policy_doc))
  end

  test "recent activity update title links to the updates list" do
    get hub_path
    assert_select "#recent_activity a[href=?]", updates_path
  end

  test "recent activity titles carry the link affordance class" do
    get hub_path
    assert_select "#recent_activity a.link"
  end
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run: `bin/rails test test/controllers/hub_controller_test.rb`
Expected: the 5 new tests FAIL (the titles are currently `<p>` elements, so no matching `#recent_activity a[href=...]` anchors exist). The 3 pre-existing tests still pass.

- [ ] **Step 3: Implement — render titles as links**

In `app/views/components/dashboard/activity_item_component.rb`, replace the three title `p(...)` lines with anchors and add a private helper.

Replace `render_feedback_content`:

```ruby
    def render_feedback_content
      a(href: feedback_link, class: "link link-hover block text-sm font-medium truncate") do
        plain "#{@item.feedback_template.name} — #{@item.csr_name || 'Unknown CSR'}"
      end
      p(class: "text-xs text-base-content/60 truncate") do
        plain "Ticket: #{@item.ticket_number || '—'} | Priority: #{@item.priority || '—'}"
      end
    end
```

Replace `render_article_content`:

```ruby
    def render_article_content
      a(href: article_path(@item), class: "link link-hover block text-sm font-medium truncate") { @item.title }
      p(class: "text-xs text-base-content/60 truncate") do
        plain "by #{@item.author.name}"
      end
    end
```

Replace `render_update_content`:

```ruby
    def render_update_content
      a(href: updates_path, class: "link link-hover block text-sm font-medium truncate") do
        plain "Standup Update — #{@item.date.strftime('%b %d, %Y')}"
      end
      p(class: "text-xs text-base-content/60 truncate") do
        plain "by #{@item.author.name}"
        if @item.pinned?
          plain " "
          Badge(:primary, :xs) { "Pinned" }
        end
      end
    end
```

Add this private method (e.g. directly below `render_update_content`, still in the `private` section):

```ruby
    def feedback_link
      @item.ticket_number.present? ? feedback_index_path(q: @item.ticket_number) : feedback_index_path
    end
```

Leave `render_type_badge`, `render_content`, `render_time`, `type_label`, and `type_modifier` unchanged.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bin/rails test test/controllers/hub_controller_test.rb`
Expected: all tests PASS (8 total: 3 pre-existing + 5 new).

- [ ] **Step 5: Run the full suite**

Run: `bin/rails test`
Expected: PASS, 0 failures / 0 errors (was 134 runs; now ~139 with the new tests).

- [ ] **Step 6: Visual check (optional but recommended)**

The dev DB (port 3006) has no activity records, so the live feed shows "No recent activity." If you want a visual confirmation, render against the test data instead of seeding the dev DB. Otherwise the integration test (asserting real hrefs) is the gate. Do NOT add records to the development database.

- [ ] **Step 7: Commit**

```bash
git add app/views/components/dashboard/activity_item_component.rb test/controllers/hub_controller_test.rb
git commit -m "feat: link recent activity titles to relevant destinations"
```

(No AI/Claude attribution in the commit message — per `.claude/rules/git-commits.md`.)

---

## Self-Review Notes

- **Spec coverage:** title→link per type (Task 1 Step 3); feedback filtered-by-ticket with blank fallback (`feedback_link` helper + the two feedback tests incl. `simple_submission`); article→show and update→list (tests); `link link-hover` affordance (`a.link` test); only the title changes, row/badge/subtitle/timestamp untouched (Step 3 leaves them). All spec behaviors map to a test.
- **No placeholders:** every step has exact code/commands.
- **Type consistency:** `feedback_link` defined once and referenced in `render_feedback_content`; element is `a` (Phlex anchor), DaisyUI class is `link` — not confused with a `<link>` tag.
- **Single task** is correct: one file of production change with a paired test cycle; nothing a reviewer could accept/reject independently of the rest.
