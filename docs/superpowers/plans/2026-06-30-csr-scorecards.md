# CSR Scorecards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give managers a per-CSR dashboard of feedback (issue) trends and breakdowns over a chosen date range, for use in 1-on-1s.

**Architecture:** A pure-Ruby `ScorecardReport` value object aggregates `FeedbackSubmission` rows (via the existing case-insensitive `for_csrs` scope) for a date range and the equal-length preceding window. A `ScorecardsController` (index + show, query-param routed) authorizes access server-side and renders Phlex components. No new tables, no migrations, no JS charting — the trend is inline SVG.

**Tech Stack:** Rails 8.1, Phlex 2.4 + PhlexyUI (DaisyUI), Minitest, SQLite.

## Global Constraints

- Views are **Phlex components** under `app/views/components/`, inheriting `ApplicationComponent`. No ERB.
- Reuse `FeedbackSubmission.for_csrs(names)` for all CSR matching — **never** write a new name matcher (preserves app-wide case-insensitive behavior).
- `impact` is **not** a DB column — it lives only in JSON `data["impact"]`. `priority`, `feedback_type`, `csr_name` **are** columns.
- Authorization is enforced **in the controller**, not by which tiles render. Managers see only their team's CSRs; **empty-team managers see no scorecards** (mirror the digest, not the feedback view's global fallback); admins see all.
- CSR is passed as a **query param** (`?csr=`), not a path segment (names contain spaces/dots).
- No AI attribution in commit messages.
- Run tests with `bin/rails test <path>`.

---

### Task 1: `ScorecardReport` aggregation object

**Files:**
- Create: `app/models/scorecard_report.rb`
- Test: `test/models/scorecard_report_test.rb`

**Interfaces:**
- Consumes: `FeedbackSubmission.for_csrs` (existing scope), `FeedbackSubmission` columns `priority`, `feedback_type`, `csr_name`, `created_at`, and JSON `data["impact"]`.
- Produces (relied on by Tasks 3 & 4):
  - `ScorecardReport.new(csr_name:, date_range: nil)` — `date_range` is a `Range` of `Time`; defaults to last 30 days.
  - `ScorecardReport.default_range -> Range<Time>`
  - `#csr_name -> String`, `#date_range -> Range<Time>`
  - `#total_count -> Integer`, `#previous_count -> Integer`, `#delta -> Integer` (`total_count - previous_count`)
  - `#severity_counts -> Hash{String=>Integer}` ordered High, Medium, Low
  - `#category_counts -> Hash{String=>Integer}` sorted by count desc
  - `#impact_counts -> Hash{String=>Integer}` sorted by count desc
  - `#trend_buckets -> Array<{label: String, count: Integer}>`
  - `#recent(limit = 5) -> Array<FeedbackSubmission>` newest first
  - `#empty? -> Boolean` (no submissions ever for this CSR)
  - `#zero_in_period? -> Boolean` (`total_count.zero?`)

- [ ] **Step 1: Write the failing test**

Create `test/models/scorecard_report_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ScorecardReportTest < ActiveSupport::TestCase
  def build_submission(csr:, created_at:, priority: "High", feedback_type: "Knowledge Gap", impact: "Resolution Time")
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      created_at: created_at,
      updated_at: created_at,
      data: {
        "ticket_number" => "TK-#{rand(10_000)}",
        "csr" => csr,
        "feedback_type" => feedback_type,
        "impact" => impact,
        "priority" => priority,
        "submitted_by" => "Tester"
      }
    )
  end

  test "matches CSR name case-insensitively via for_csrs" do
    build_submission(csr: "Bob Lee", created_at: 2.days.ago)
    report = ScorecardReport.new(csr_name: "bob lee")
    assert_equal 1, report.total_count
    assert_not report.empty?
  end

  test "counts only submissions inside the range and computes delta vs previous window" do
    range = (10.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Cara Diaz", created_at: 3.days.ago)   # in range
    build_submission(csr: "Cara Diaz", created_at: 5.days.ago)   # in range
    build_submission(csr: "Cara Diaz", created_at: 15.days.ago)  # previous window
    report = ScorecardReport.new(csr_name: "Cara Diaz", date_range: range)
    assert_equal 2, report.total_count
    assert_equal 1, report.previous_count
    assert_equal 1, report.delta
  end

  test "breaks down severity, category, and impact for the period" do
    range = (10.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Dan Fox", created_at: 1.day.ago, priority: "High", feedback_type: "Knowledge Gap", impact: "Resolution Time")
    build_submission(csr: "Dan Fox", created_at: 2.days.ago, priority: "High", feedback_type: "Process Failure", impact: "Client Experience")
    build_submission(csr: "Dan Fox", created_at: 3.days.ago, priority: "Low", feedback_type: "Knowledge Gap", impact: "Resolution Time")
    report = ScorecardReport.new(csr_name: "Dan Fox", date_range: range)

    assert_equal({ "High" => 2, "Medium" => 0, "Low" => 1 }, report.severity_counts)
    assert_equal({ "Knowledge Gap" => 2, "Process Failure" => 1 }, report.category_counts)
    assert_equal({ "Resolution Time" => 2, "Client Experience" => 1 }, report.impact_counts)
  end

  test "trend buckets cover the range and place boundary submissions correctly" do
    range = (14.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Eve Gray", created_at: 14.days.ago.beginning_of_day + 1.hour) # first bucket
    build_submission(csr: "Eve Gray", created_at: Time.current - 1.hour)                 # last bucket
    report = ScorecardReport.new(csr_name: "Eve Gray", date_range: range)
    buckets = report.trend_buckets

    assert_operator buckets.size, :>=, 2
    assert_equal 2, buckets.sum { |b| b[:count] }
    assert_operator buckets.first[:count], :>=, 1
    assert_operator buckets.last[:count], :>=, 1
  end

  test "recent returns newest first, limited" do
    newest = build_submission(csr: "Fin Hall", created_at: 1.day.ago)
    build_submission(csr: "Fin Hall", created_at: 4.days.ago)
    report = ScorecardReport.new(csr_name: "Fin Hall")
    assert_equal newest.id, report.recent(1).first.id
  end

  test "empty? true for unknown CSR; zero_in_period? true when all issues fall outside the range" do
    assert ScorecardReport.new(csr_name: "Nobody Here").empty?

    range = (5.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Gus Ives", created_at: 30.days.ago)
    report = ScorecardReport.new(csr_name: "Gus Ives", date_range: range)
    assert_not report.empty?
    assert report.zero_in_period?
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/scorecard_report_test.rb`
Expected: FAIL with `uninitialized constant ScorecardReport`.

- [ ] **Step 3: Write minimal implementation**

Create `app/models/scorecard_report.rb`:

```ruby
# frozen_string_literal: true

# Aggregates feedback (issues) logged against a single CSR over a date range,
# plus the equal-length immediately-preceding window, for the manager scorecard.
#
# Pure value object: reads FeedbackSubmission via the shared `for_csrs` scope and
# computes breakdowns in Ruby. Feedback volume is low, and `impact` lives only in
# JSON `data`, so DB-side grouping is not uniformly available.
class ScorecardReport
  DEFAULT_RANGE_DAYS = 30
  WEEKLY_BUCKET_MAX_DAYS = 90

  attr_reader :csr_name, :date_range

  def initialize(csr_name:, date_range: nil)
    @csr_name = csr_name.to_s
    @date_range = date_range || self.class.default_range
  end

  def self.default_range
    DEFAULT_RANGE_DAYS.days.ago.beginning_of_day..Time.current.end_of_day
  end

  def total_count
    current_submissions.size
  end

  def previous_count
    @previous_count ||= base.where(created_at: previous_range).count
  end

  def delta
    total_count - previous_count
  end

  def severity_counts
    ordered_tally(current_submissions.map(&:priority), %w[High Medium Low])
  end

  def category_counts
    tally_desc(current_submissions.map(&:feedback_type))
  end

  def impact_counts
    tally_desc(current_submissions.map { |s| s.data["impact"] })
  end

  def trend_buckets
    counts = Hash.new(0)
    current_submissions.each { |s| counts[bucket_key(s.created_at)] += 1 }
    bucket_starts.map { |start| { label: bucket_label(start), count: counts[start] } }
  end

  def recent(limit = 5)
    current_submissions.first(limit)
  end

  def empty?
    base.none?
  end

  def zero_in_period?
    total_count.zero?
  end

  private

  def base
    FeedbackSubmission.for_csrs(csr_name)
  end

  def current_submissions
    @current_submissions ||= base.where(created_at: date_range).order(created_at: :desc).to_a
  end

  def previous_range
    length = date_range.end - date_range.begin
    (date_range.begin - length)...date_range.begin
  end

  def bucket_unit
    span_days = (date_range.end.to_date - date_range.begin.to_date).to_i
    span_days > WEEKLY_BUCKET_MAX_DAYS ? :month : :week
  end

  def bucket_key(time)
    t = time.to_time
    bucket_unit == :month ? t.beginning_of_month.to_date : t.beginning_of_week.to_date
  end

  def bucket_starts
    step = bucket_unit == :month ? 1.month : 1.week
    cursor = bucket_key(date_range.begin)
    last = bucket_key(date_range.end)
    starts = []
    while cursor <= last
      starts << cursor
      cursor += step
    end
    starts
  end

  def bucket_label(start)
    bucket_unit == :month ? start.strftime("%b") : start.strftime("%-m/%-d")
  end

  def ordered_tally(values, order)
    counts = values.compact.tally
    order.to_h { |key| [key, counts.fetch(key, 0)] }
  end

  def tally_desc(values)
    values.compact.tally.sort_by { |_label, count| -count }.to_h
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/scorecard_report_test.rb`
Expected: PASS (6 runs, 0 failures, 0 errors).

- [ ] **Step 5: Commit**

```bash
git add app/models/scorecard_report.rb test/models/scorecard_report_test.rb
git commit -m "feat: add ScorecardReport aggregation for CSR feedback trends"
```

---

### Task 2: Presentational components (trend chart + breakdown bars)

**Files:**
- Create: `app/views/components/scorecards/trend_chart_component.rb`
- Create: `app/views/components/scorecards/breakdown_component.rb`
- Test: `test/components/scorecards/trend_chart_component_test.rb`
- Test: `test/components/scorecards/breakdown_component_test.rb`

**Interfaces:**
- Consumes: nothing from other tasks — both take plain Ruby data (no route helpers, no `current_user`), so they render standalone via `.call`.
- Produces (relied on by Task 3):
  - `Scorecards::TrendChartComponent.new(buckets:)` — `buckets` is `Array<{label:, count:}>` (the shape returned by `ScorecardReport#trend_buckets`).
  - `Scorecards::BreakdownComponent.new(title:, counts:)` — `counts` is an ordered `Hash{String=>Integer}` (the shape returned by the report's `*_counts` methods).

- [ ] **Step 1: Write the failing tests**

Create `test/components/scorecards/trend_chart_component_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class Scorecards::TrendChartComponentTest < ActiveSupport::TestCase
  test "renders an svg bar per bucket when there are issues" do
    html = Scorecards::TrendChartComponent.new(
      buckets: [ { label: "6/1", count: 2 }, { label: "6/8", count: 0 }, { label: "6/15", count: 3 } ]
    ).call
    assert_includes html, "<svg"
    assert_equal 3, html.scan("<rect").size
    assert_includes html, "6/15"
  end

  test "renders an empty-state message when all buckets are zero" do
    html = Scorecards::TrendChartComponent.new(
      buckets: [ { label: "6/1", count: 0 }, { label: "6/8", count: 0 } ]
    ).call
    assert_not_includes html, "<rect"
    assert_includes html, "No issues"
  end
end
```

Create `test/components/scorecards/breakdown_component_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class Scorecards::BreakdownComponentTest < ActiveSupport::TestCase
  test "renders a labeled row per entry" do
    html = Scorecards::BreakdownComponent.new(
      title: "Severity", counts: { "High" => 2, "Medium" => 0, "Low" => 1 }
    ).call
    assert_includes html, "Severity"
    assert_includes html, "High"
    assert_includes html, "Low"
  end

  test "renders an empty state when every count is zero" do
    html = Scorecards::BreakdownComponent.new(
      title: "Category", counts: { "Knowledge Gap" => 0 }
    ).call
    assert_includes html, "None in this period"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/components/scorecards/trend_chart_component_test.rb test/components/scorecards/breakdown_component_test.rb`
Expected: FAIL with `uninitialized constant Scorecards::TrendChartComponent` / `Scorecards::BreakdownComponent`.

- [ ] **Step 3: Write minimal implementations**

Create `app/views/components/scorecards/trend_chart_component.rb`:

```ruby
# frozen_string_literal: true

module Scorecards
  # Inline-SVG bar chart of issue counts per time bucket. No JS.
  class TrendChartComponent < ApplicationComponent
    BAR_WIDTH = 24
    BAR_GAP = 8
    CHART_HEIGHT = 80

    def initialize(buckets:)
      @buckets = buckets
    end

    def view_template
      max = @buckets.map { |b| b[:count] }.max.to_i
      if max.zero?
        p(class: "text-sm text-base-content/60") { "No issues in this period." }
      else
        render_chart(max)
      end
    end

    private

    def render_chart(max)
      width = @buckets.size * (BAR_WIDTH + BAR_GAP)
      svg(viewBox: "0 0 #{width} #{CHART_HEIGHT + 20}", class: "w-full h-28 text-primary", role: "img") do |s|
        @buckets.each_with_index do |bucket, i|
          height = (bucket[:count].to_f / max * CHART_HEIGHT).round
          x = i * (BAR_WIDTH + BAR_GAP)
          s.rect(x: x, y: CHART_HEIGHT - height, width: BAR_WIDTH, height: height, rx: 2, fill: "currentColor")
          s.text(
            x: x + BAR_WIDTH / 2, y: CHART_HEIGHT + 14,
            "text-anchor": "middle", fill: "currentColor",
            class: "text-[8px] opacity-60"
          ) { bucket[:label] }
        end
      end
    end
  end
end
```

Create `app/views/components/scorecards/breakdown_component.rb`:

```ruby
# frozen_string_literal: true

module Scorecards
  # A titled list of "label — bar — count" rows. Reused for severity,
  # category, and impact breakdowns. `counts` is an ordered Hash.
  class BreakdownComponent < ApplicationComponent
    def initialize(title:, counts:)
      @title = title
      @counts = counts
    end

    def view_template
      Card class: "surface" do |card|
        card.body do
          h3(class: "card-title text-sm font-bold mb-3") { @title }
          if @counts.values.sum.zero?
            p(class: "text-sm text-base-content/60") { "None in this period." }
          else
            div(class: "space-y-2") do
              max = @counts.values.max
              @counts.each { |label, count| render_row(label, count, max) }
            end
          end
        end
      end
    end

    private

    def render_row(label, count, max)
      pct = max.zero? ? 0 : (count.to_f / max * 100).round
      div(class: "flex items-center gap-2 text-sm") do
        span(class: "w-32 shrink-0 truncate") { label }
        div(class: "flex-1 bg-base-200 rounded h-3 overflow-hidden") do
          div(class: "bg-primary h-3 rounded", style: "width: #{pct}%")
        end
        span(class: "w-6 text-right tabular-nums") { count.to_s }
      end
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bin/rails test test/components/scorecards/trend_chart_component_test.rb test/components/scorecards/breakdown_component_test.rb`
Expected: PASS (4 runs, 0 failures, 0 errors).

- [ ] **Step 5: Commit**

```bash
git add app/views/components/scorecards/trend_chart_component.rb app/views/components/scorecards/breakdown_component.rb test/components/scorecards/
git commit -m "feat: add scorecard trend chart and breakdown components"
```

---

### Task 3: Show + index components

**Files:**
- Create: `app/views/components/scorecards/show_component.rb`
- Create: `app/views/components/scorecards/index_component.rb`

**Interfaces:**
- Consumes: `ScorecardReport` (Task 1); `Scorecards::TrendChartComponent`, `Scorecards::BreakdownComponent` (Task 2); route helpers `scorecard_path(csr:)`, `scorecards_path`, `feedback_path(submission)`, `team_path`.
- Produces (relied on by Task 4):
  - `Scorecards::ShowComponent.new(report:)` — `report` is a `ScorecardReport`.
  - `Scorecards::IndexComponent.new(tiles:)` — `tiles` is `Array<{csr_name: String, count: Integer, delta: Integer}>`.

> These components use route helpers and are exercised by the controller integration tests in Task 4 (standalone `.call` would lack a view context). There is no separate unit test step here; do not add cheater tests that stub routing.

- [ ] **Step 1: Write the show component**

Create `app/views/components/scorecards/show_component.rb`:

```ruby
# frozen_string_literal: true

module Scorecards
  class ShowComponent < ApplicationComponent
    def initialize(report:)
      @report = report
    end

    def view_template
      div(class: "space-y-6") do
        render_header
        render_date_form
        if @report.empty?
          render_no_data
        else
          render_volume_panel
          div(class: "grid grid-cols-1 lg:grid-cols-3 gap-4") do
            render BreakdownComponent.new(title: "Severity", counts: @report.severity_counts)
            render BreakdownComponent.new(title: "Category", counts: @report.category_counts)
            render BreakdownComponent.new(title: "Impact", counts: @report.impact_counts)
          end
          render_recent
        end
      end
    end

    private

    def render_header
      div(class: "flex items-center justify-between") do
        div do
          h1(class: "page-title") { @report.csr_name }
          p(class: "text-sm text-base-content/60") { "Scorecard" }
        end
        a(href: scorecards_path, class: "btn btn-ghost btn-sm") { "All scorecards" }
      end
    end

    def render_date_form
      form(action: scorecard_path, method: "get", class: "flex flex-wrap items-end gap-2") do
        input(type: "hidden", name: "csr", value: @report.csr_name)
        render_date_field("start", @report.date_range.begin.to_date)
        render_date_field("end", @report.date_range.end.to_date)
        Button(:primary, :sm, type: "submit") { "Apply" }
      end
    end

    def render_date_field(name, value)
      div(class: "form-control") do
        label(class: "label") { span(class: "label-text text-xs capitalize") { name } }
        input(type: "date", name: name, value: value.iso8601, class: "input input-bordered input-sm")
      end
    end

    def render_no_data
      Card class: "surface" do |card|
        card.body class: "items-center text-center" do
          p(class: "text-base-content/60") { "No feedback on record for #{@report.csr_name} yet." }
        end
      end
    end

    def render_volume_panel
      Card class: "surface" do |card|
        card.body do
          div(class: "flex items-baseline justify-between") do
            h2(class: "card-title text-lg font-bold") { "Issue volume" }
            render_delta
          end
          if @report.zero_in_period?
            p(class: "text-success font-medium mt-2") { "No issues logged this period \u{1F389}" }
          else
            p(class: "text-4xl font-bold mt-1") { @report.total_count.to_s }
          end
          div(class: "mt-4") { render TrendChartComponent.new(buckets: @report.trend_buckets) }
        end
      end
    end

    def render_delta
      delta = @report.delta
      if delta.positive?
        span(class: "badge badge-error badge-soft") { "▲ #{delta} vs previous" }
      elsif delta.negative?
        span(class: "badge badge-success badge-soft") { "▼ #{delta.abs} vs previous" }
      else
        span(class: "badge badge-ghost") { "No change vs previous" }
      end
    end

    def render_recent
      Card class: "surface" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold mb-3") { "Recent issues" }
          ul(class: "space-y-2") do
            @report.recent.each { |submission| render_recent_row(submission) }
          end
        end
      end
    end

    def render_recent_row(submission)
      li do
        a(href: feedback_path(submission), class: "flex items-center justify-between p-2 rounded bg-base-200 hover:bg-base-300") do
          span(class: "font-medium") { submission.feedback_type.to_s }
          span(class: "flex items-center gap-2 text-sm text-base-content/60") do
            span { submission.priority.to_s }
            span { submission.created_at.to_date.to_fs(:long) }
          end
        end
      end
    end
  end
end
```

- [ ] **Step 2: Write the index component**

Create `app/views/components/scorecards/index_component.rb`:

```ruby
# frozen_string_literal: true

module Scorecards
  class IndexComponent < ApplicationComponent
    def initialize(tiles:)
      @tiles = tiles
    end

    def view_template
      div(class: "space-y-6") do
        h1(class: "page-title") { "Scorecards" }
        if @tiles.empty?
          render_empty_prompt
        else
          div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
            @tiles.each { |tile| render_tile(tile) }
          end
        end
      end
    end

    private

    def render_empty_prompt
      Card class: "surface" do |card|
        card.body do
          p(class: "text-base-content/60") do
            plain "No CSRs on your team yet. Add CSRs on the "
            a(href: team_path, class: "link") { "My Team" }
            plain " page to see their scorecards."
          end
        end
      end
    end

    def render_tile(tile)
      a(href: scorecard_path(csr: tile[:csr_name]), class: "block") do
        Card class: "surface hover:shadow-md transition-shadow" do |card|
          card.body do
            h2(class: "card-title text-base font-bold") { tile[:csr_name] }
            div(class: "flex items-baseline justify-between mt-2") do
              span(class: "text-3xl font-bold") { tile[:count].to_s }
              render_delta(tile[:delta])
            end
            p(class: "text-xs text-base-content/60 mt-1") { "issues, last 30 days" }
          end
        end
      end
    end

    def render_delta(delta)
      if delta.positive?
        span(class: "text-error text-sm") { "▲ #{delta}" }
      elsif delta.negative?
        span(class: "text-success text-sm") { "▼ #{delta.abs}" }
      else
        span(class: "text-base-content/40 text-sm") { "—" }
      end
    end
  end
end
```

- [ ] **Step 3: Verify the app boots (components compile)**

Run: `bin/rails runner 'Scorecards::ShowComponent; Scorecards::IndexComponent; puts "ok"'`
Expected: prints `ok` with no load errors.

- [ ] **Step 4: Commit**

```bash
git add app/views/components/scorecards/show_component.rb app/views/components/scorecards/index_component.rb
git commit -m "feat: add scorecard show and index components"
```

---

### Task 4: Routes, controller, nav link, and authorization tests

**Files:**
- Modify: `config/routes.rb` (add two routes after the `team_memberships` lines, ~line 22)
- Create: `app/controllers/scorecards_controller.rb`
- Modify: `app/views/components/layouts/application_layout.rb` (add nav item after the "My Team" block, ~line 99)
- Test: `test/controllers/scorecards_controller_test.rb`

**Interfaces:**
- Consumes: `ScorecardReport` (Task 1), `Scorecards::IndexComponent` / `Scorecards::ShowComponent` (Task 3), helpers on `ApplicationController` (`current_user`, `require_authentication`), `User#admin?` / `#manager?` / `#team_csr_names`.
- Produces: routes `scorecards_path` (`GET /scorecards`) and `scorecard_path(csr:)` (`GET /scorecards/show`).

- [ ] **Step 1: Write the failing controller test**

Create `test/controllers/scorecards_controller_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ScorecardsControllerTest < ActionDispatch::IntegrationTest
  # The `manager` fixture's team includes "Jane Doe" (team_memberships(:manager_jane)),
  # and Jane Doe has two feedback fixtures.

  test "unauthenticated user is redirected to login" do
    get scorecards_path
    assert_redirected_to login_path
  end

  test "regular user is redirected to root" do
    sign_in_as_user
    get scorecards_path
    assert_redirected_to root_path
  end

  test "manager sees the index with their team CSR" do
    sign_in_as_manager
    get scorecards_path
    assert_response :success
    assert_includes response.body, "Jane Doe"
  end

  test "manager can view a scorecard for a CSR on their team" do
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe")
    assert_response :success
    assert_includes response.body, "Issue volume"
  end

  test "manager viewing a non-team CSR is redirected with an alert" do
    sign_in_as_manager
    get scorecard_path(csr: "Someone Else")
    assert_redirected_to scorecards_path
    assert_not_nil flash[:alert]
  end

  test "empty-team manager sees the prompt and cannot view any scorecard" do
    manager = User.create!(email: "empty@test.com", name: "Empty", password: "password", role: "manager")
    sign_in(manager)

    get scorecards_path
    assert_response :success
    assert_includes response.body, "No CSRs on your team yet"

    get scorecard_path(csr: "Jane Doe")
    assert_redirected_to scorecards_path
  end

  test "admin can view any CSR scorecard" do
    sign_in_as_admin
    get scorecard_path(csr: "Jane Doe")
    assert_response :success
    assert_includes response.body, "Issue volume"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/scorecards_controller_test.rb`
Expected: FAIL with `undefined local variable or method 'scorecards_path'` (routes not defined yet).

- [ ] **Step 3: Add the routes**

In `config/routes.rb`, after line 22 (`resources :team_memberships, only: [ :create, :destroy ]`), add:

```ruby
  get "scorecards", to: "scorecards#index"
  get "scorecards/show", to: "scorecards#show", as: :scorecard
```

- [ ] **Step 4: Write the controller**

Create `app/controllers/scorecards_controller.rb`:

```ruby
class ScorecardsController < ApplicationController
  before_action :require_manager_or_admin

  def index
    render Scorecards::IndexComponent.new(tiles: tiles_for(accessible_csr_names))
  end

  def show
    csr = params[:csr].to_s
    unless authorized_for?(csr)
      redirect_to scorecards_path, alert: "That CSR is not on your team." and return
    end

    render Scorecards::ShowComponent.new(
      report: ScorecardReport.new(csr_name: csr, date_range: requested_range)
    )
  end

  private

  def require_manager_or_admin
    unless current_user&.manager? || current_user&.admin?
      redirect_to root_path, alert: "Manager access required."
    end
  end

  def accessible_csr_names
    if current_user.admin?
      FeedbackSubmission.where.not(csr_name: nil).distinct.pluck(:csr_name).sort
    else
      current_user.team_csr_names.sort
    end
  end

  def authorized_for?(csr)
    return false if csr.blank?
    return true if current_user.admin?

    current_user.team_csr_names.any? { |name| name.casecmp?(csr) }
  end

  def tiles_for(names)
    names.map do |name|
      report = ScorecardReport.new(csr_name: name)
      { csr_name: name, count: report.total_count, delta: report.delta }
    end
  end

  def requested_range
    start_date = parse_date(params[:start])
    end_date = parse_date(params[:end])
    return ScorecardReport.default_range unless start_date && end_date

    start_date.beginning_of_day..end_date.end_of_day
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
```

- [ ] **Step 5: Add the nav link**

In `app/views/components/layouts/application_layout.rb`, immediately after the `if current_user&.manager?` "My Team" block (closes at line 99), add:

```ruby
            if current_user&.manager? || current_user&.admin?
              menu.item do
                a(href: scorecards_path, class: "flex items-center gap-2") do
                  render_icon("M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z")
                  plain "Scorecards"
                end
              end
            end
```

- [ ] **Step 6: Run the controller test to verify it passes**

Run: `bin/rails test test/controllers/scorecards_controller_test.rb`
Expected: PASS (7 runs, 0 failures, 0 errors).

- [ ] **Step 7: Run the full suite for regressions**

Run: `bin/rails test`
Expected: all green (no regressions in feedback/team/layout tests).

- [ ] **Step 8: Commit**

```bash
git add config/routes.rb app/controllers/scorecards_controller.rb app/views/components/layouts/application_layout.rb test/controllers/scorecards_controller_test.rb
git commit -m "feat: add scorecards controller, routes, and nav entry"
```

---

## Self-Review Notes

**Spec coverage:**
- No single score → no score computed anywhere; report exposes counts/trends only. ✓
- Period comparison + trend → `previous_range`/`delta` + `trend_buckets` + `TrendChartComponent`; default 30 days, equal-length preceding window. ✓ (Task 1, 2, 3)
- Four panels (volume+trend, severity, category, impact+recent) → `ShowComponent`. ✓ (Task 3)
- Authorization server-side; empty-team = no scorecards; admins all → `ScorecardsController` + tests. ✓ (Task 4)
- Query-param routing → `GET /scorecards/show?csr=`. ✓ (Task 4)
- Zero-issue good state distinct from no-data and not-on-team → `zero_in_period?` panel vs `empty?` no-data vs `show` redirect. ✓ (Task 1, 3, 4)
- Index tiles + empty-team prompt; nav entry → `IndexComponent` + layout. ✓ (Task 3, 4)
- Non-goal (name normalization) → matching delegated entirely to `for_csrs`; no new matcher. ✓
- Tests: report unit (matching, bucket boundary, delta, empty/zero), controller auth (own-team, non-team denied, empty-team, admin, unauth), component smoke (trend, breakdown). ✓

**Type consistency:** `trend_buckets` returns `[{label:, count:}]` — consumed identically by `TrendChartComponent`. `*_counts` return ordered `Hash` — consumed by `BreakdownComponent`. `tiles` shape `{csr_name:, count:, delta:}` produced by `tiles_for`, consumed by `IndexComponent`. `scorecard_path(csr:)` defined in Task 4, used in Task 3. Consistent.

**Placeholders:** none.
