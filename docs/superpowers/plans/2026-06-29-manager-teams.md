# Manager Teams & Team-Scoped Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `manager` role whose holders configure a team of CSR names, see only their team's feedback (home + feedback pages), and receive a daily digest email of new team feedback.

**Architecture:** A new `team_memberships` join table links a manager (User) to free-text CSR name strings matched case-insensitively against `feedback_submissions.csr_name`. Controllers scope feedback to the current manager's team; Turbo Stream broadcasts fan out to per-manager channels so the live feed stays filtered; a recurring Solid Queue job mails each manager a daily digest of feedback since their watermark.

**Tech Stack:** Rails 8.1, Phlex 2.4 + PhlexyUI, Turbo Streams, Solid Queue (recurring), Minitest with fixtures, SQLite.

## Global Constraints

- CSRs stay **free-text strings**; no CSR table or account. Match against `feedback_submissions.csr_name`.
- CSR matching is **case-insensitive** everywhere (filter, digest, membership uniqueness, broadcast targeting) via `LOWER()`. SQLite `=`/`IN` on text is case-sensitive by default.
- Only **managers with a non-empty team** are scoped. Admins, regular users, and **empty-team managers fall back to the global view** (view layer only).
- The **digest never uses the empty-team fallback**: it queries `for_csrs(team)` directly, so an empty team yields an empty set and the manager is skipped.
- No AI attribution in commit messages.
- The live home page is `Dashboard::IndexComponent` (rendered by `HubController#index`). `Hub::IndexComponent` is **dead code — do not touch it.**
- Follow existing Phlex component patterns (`app/views/components/**`, inherit `ApplicationComponent`, PhlexyUI helpers like `Button`, `Badge`, `Card`).
- Run tests with `bin/rails test` (per the test-runner rule, use the test-runner agent when executing).

---

### Task 1: Manager role on User

**Files:**
- Modify: `app/models/user.rb:9` (role validation), add `manager?` helper
- Modify: `app/views/components/admin/user_form_component.rb:53`
- Modify: `test/fixtures/users.yml`
- Modify: `test/test_helper.rb` (add `sign_in_as_manager`)
- Test: `test/models/user_test.rb`

**Interfaces:**
- Produces: `User.role` accepts `"manager"`; `User#manager?` → Boolean; fixture `users(:manager)`; helper `sign_in_as_manager`.

- [ ] **Step 1: Add the manager fixture**

In `test/fixtures/users.yml`, append:

```yaml
manager:
  email: "manager@test.com"
  name: "Manager User"
  password_digest: <%= BCrypt::Password.create("password") %>
  role: "manager"
```

- [ ] **Step 2: Write failing model tests**

In `test/models/user_test.rb`, add before the final `end`:

```ruby
  test "accepts manager role" do
    user = User.new(email: "m@test.com", name: "Mgr", password: "password", role: "manager")
    assert user.valid?
  end

  test "manager? returns true for manager role" do
    assert users(:manager).manager?
  end

  test "manager? returns false for non-manager roles" do
    assert_not users(:admin).manager?
    assert_not users(:regular).manager?
  end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bin/rails test test/models/user_test.rb -v`
Expected: FAIL — `accepts manager role` fails on inclusion validation; `manager?` fails with NoMethodError.

- [ ] **Step 4: Implement role + helper**

In `app/models/user.rb`, change the role validation line and add the helper:

```ruby
  validates :role, presence: true, inclusion: { in: %w[admin user manager] }

  def admin?
    role == "admin"
  end

  def manager?
    role == "manager"
  end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bin/rails test test/models/user_test.rb -v`
Expected: PASS (all).

- [ ] **Step 6: Add manager to the admin role select**

In `app/views/components/admin/user_form_component.rb`, change line 53:

```ruby
            %w[user admin manager].each do |role|
```

- [ ] **Step 7: Add the manager sign-in helper**

In `test/test_helper.rb`, inside `module AuthenticationHelper`, add after `sign_in_as_user`:

```ruby
  def sign_in_as_manager
    sign_in(users(:manager))
  end
```

- [ ] **Step 8: Run the full model + admin suite**

Run: `bin/rails test test/models/user_test.rb test/controllers/admin/users_controller_test.rb -v`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add app/models/user.rb app/views/components/admin/user_form_component.rb test/fixtures/users.yml test/test_helper.rb test/models/user_test.rb
git commit -m "feat: add manager role to User"
```

---

### Task 2: TeamMembership model, migration, and User scoping helpers

**Files:**
- Create: `db/migrate/20260629120000_create_team_memberships.rb`
- Create: `db/migrate/20260629120001_add_last_digest_sent_at_to_users.rb`
- Create: `app/models/team_membership.rb`
- Modify: `app/models/user.rb` (associations + helpers)
- Modify: `app/models/feedback_submission.rb` (`for_csrs` scope)
- Create: `test/fixtures/team_memberships.yml`
- Create: `test/models/team_membership_test.rb`
- Test: `test/models/feedback_submission_test.rb`, `test/models/user_test.rb`

**Interfaces:**
- Consumes: `User#manager?` (Task 1), `users(:manager)` fixture.
- Produces:
  - `TeamMembership` `belongs_to :manager, class_name: "User"`, validations.
  - `User#team_memberships`, `User#team_csr_names` → `Array<String>`, `User#team_scoped?` → Boolean, `User#stream_for(base)` → String, `User.managers_for(csr_name)` → `ActiveRecord::Relation`.
  - `FeedbackSubmission.for_csrs(names)` → `ActiveRecord::Relation` (case-insensitive; empty/blank names → `none`).
  - `users.last_digest_sent_at` column.
  - Fixture `team_memberships(:manager_jane)` for `users(:manager)` + `"Jane Doe"`.

- [ ] **Step 1: Write the migrations**

Create `db/migrate/20260629120000_create_team_memberships.rb`:

```ruby
class CreateTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :team_memberships do |t|
      t.references :manager, null: false, foreign_key: { to_table: :users }
      t.string :csr_name, null: false
      t.timestamps
    end
    add_index :team_memberships, [:manager_id, :csr_name], unique: true
  end
end
```

Create `db/migrate/20260629120001_add_last_digest_sent_at_to_users.rb`:

```ruby
class AddLastDigestSentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_digest_sent_at, :datetime
  end
end
```

- [ ] **Step 2: Run the migrations**

Run: `bin/rails db:migrate`
Expected: both migrations apply; `db/schema.rb` updated with `team_memberships` and `users.last_digest_sent_at`. (Additive only — never `db:reset`/`db:drop`.)

- [ ] **Step 3: Add the TeamMembership fixture**

Create `test/fixtures/team_memberships.yml`:

```yaml
manager_jane:
  manager: manager
  csr_name: "Jane Doe"
```

- [ ] **Step 4: Write failing model tests**

Create `test/models/team_membership_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class TeamMembershipTest < ActiveSupport::TestCase
  test "valid membership saves" do
    m = TeamMembership.new(manager: users(:manager), csr_name: "New CSR")
    assert m.save
  end

  test "requires csr_name" do
    m = TeamMembership.new(manager: users(:manager))
    assert_not m.valid?
    assert_includes m.errors[:csr_name], "can't be blank"
  end

  test "csr_name unique per manager, case-insensitive" do
    dup = TeamMembership.new(manager: users(:manager), csr_name: "jane doe")
    assert_not dup.valid?
    assert_includes dup.errors[:csr_name], "has already been taken"
  end

  test "belongs to a manager" do
    assert_equal users(:manager), team_memberships(:manager_jane).manager
  end
end
```

In `test/models/user_test.rb`, add before the final `end`:

```ruby
  test "team_csr_names lists the manager's CSR names" do
    assert_equal ["Jane Doe"], users(:manager).team_csr_names
  end

  test "team_scoped? true for manager with memberships" do
    assert users(:manager).team_scoped?
  end

  test "team_scoped? false for admin and empty-team manager" do
    assert_not users(:admin).team_scoped?
    empty = User.create!(email: "empty@test.com", name: "Empty", password: "password", role: "manager")
    assert_not empty.team_scoped?
  end

  test "stream_for namespaces the channel for scoped managers" do
    assert_equal "dashboard:#{users(:manager).id}", users(:manager).stream_for("dashboard")
    assert_equal "dashboard", users(:admin).stream_for("dashboard")
  end

  test "managers_for returns managers whose team includes the csr name (case-insensitive)" do
    assert_includes User.managers_for("jane doe"), users(:manager)
    assert_empty User.managers_for("Nobody")
  end
```

In `test/models/feedback_submission_test.rb`, add a `for_csrs` test (place before the final `end`):

```ruby
  test "for_csrs matches case-insensitively and ignores blanks" do
    assert_includes FeedbackSubmission.for_csrs(["jane doe"]), feedback_submissions(:high_priority)
    assert_empty FeedbackSubmission.for_csrs([])
    assert_empty FeedbackSubmission.for_csrs(nil)
  end
```

- [ ] **Step 5: Run tests to verify they fail**

Run: `bin/rails test test/models/team_membership_test.rb test/models/user_test.rb test/models/feedback_submission_test.rb -v`
Expected: FAIL — `TeamMembership` undefined / `team_csr_names`, `team_scoped?`, `stream_for`, `managers_for`, `for_csrs` undefined.

- [ ] **Step 6: Create the TeamMembership model**

Create `app/models/team_membership.rb`:

```ruby
class TeamMembership < ApplicationRecord
  belongs_to :manager, class_name: "User"

  validates :csr_name, presence: true,
    uniqueness: { scope: :manager_id, case_sensitive: false }
end
```

- [ ] **Step 7: Add User associations and helpers**

In `app/models/user.rb`, add the association near the others and the helpers near `manager?`:

```ruby
  has_many :team_memberships, foreign_key: :manager_id, dependent: :destroy
```

```ruby
  def team_csr_names
    team_memberships.pluck(:csr_name)
  end

  def team_scoped?
    manager? && team_memberships.exists?
  end

  def stream_for(base)
    team_scoped? ? "#{base}:#{id}" : base
  end

  def self.managers_for(csr_name)
    return none if csr_name.blank?

    where(role: "manager").where(
      id: TeamMembership.where("LOWER(csr_name) = ?", csr_name.to_s.downcase).select(:manager_id)
    )
  end
```

- [ ] **Step 8: Add the for_csrs scope**

In `app/models/feedback_submission.rb`, add after the existing scopes:

```ruby
  scope :for_csrs, ->(names) {
    names = Array(names).map { |n| n.to_s.downcase }.reject(&:blank?)
    next none if names.empty?
    where("LOWER(csr_name) IN (?)", names)
  }
```

- [ ] **Step 9: Run tests to verify they pass**

Run: `bin/rails test test/models/team_membership_test.rb test/models/user_test.rb test/models/feedback_submission_test.rb -v`
Expected: PASS (all).

- [ ] **Step 10: Commit**

```bash
git add db/migrate/20260629120000_create_team_memberships.rb db/migrate/20260629120001_add_last_digest_sent_at_to_users.rb db/schema.rb app/models/team_membership.rb app/models/user.rb app/models/feedback_submission.rb test/fixtures/team_memberships.yml test/models/team_membership_test.rb test/models/user_test.rb test/models/feedback_submission_test.rb
git commit -m "feat: add team memberships and CSR scoping helpers"
```

---

### Task 3: Team configuration UI

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/application_controller.rb` (`require_manager`)
- Create: `app/controllers/team_memberships_controller.rb`
- Create: `app/views/components/team/index_component.rb`
- Modify: `app/views/components/layouts/application_layout.rb` (nav link, after the `feedback_index_path` item ~line 87)
- Create: `test/controllers/team_memberships_controller_test.rb`

**Interfaces:**
- Consumes: `current_user.team_memberships`, `current_user.manager?` (Tasks 1–2), `FeedbackSubmission.distinct.pluck(:csr_name)`.
- Produces: routes `team_path` (GET `/team`), `team_memberships_path` (POST), `team_membership_path(id)` (DELETE); `require_manager` before_action helper; `Team::IndexComponent.new(memberships:, csr_suggestions:)`.

- [ ] **Step 1: Add routes**

In `config/routes.rb`, add after the `resources :feedback ... end` block:

```ruby
  get "team", to: "team_memberships#index"
  resources :team_memberships, only: [ :create, :destroy ]
```

- [ ] **Step 2: Add require_manager**

In `app/controllers/application_controller.rb`, add after `require_admin`:

```ruby
  def require_manager
    unless current_user&.manager?
      redirect_to root_path, alert: "Manager access required."
    end
  end
```

- [ ] **Step 3: Write failing controller tests**

Create `test/controllers/team_memberships_controller_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class TeamMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as_manager }

  test "index renders for a manager" do
    get team_path
    assert_response :success
  end

  test "non-manager is redirected" do
    sign_in_as_user
    get team_path
    assert_redirected_to root_path
  end

  test "create adds a CSR to the team" do
    assert_difference "TeamMembership.count", 1 do
      post team_memberships_path, params: { csr_name: "Carlos Reyes" }
    end
    assert_redirected_to team_path
  end

  test "create rejects a duplicate CSR" do
    assert_no_difference "TeamMembership.count" do
      post team_memberships_path, params: { csr_name: "Jane Doe" }
    end
    assert_redirected_to team_path
    assert_not_nil flash[:alert]
  end

  test "create rejects a blank CSR" do
    assert_no_difference "TeamMembership.count" do
      post team_memberships_path, params: { csr_name: "" }
    end
    assert_redirected_to team_path
    assert_not_nil flash[:alert]
  end

  test "destroy removes a CSR from the team" do
    membership = team_memberships(:manager_jane)
    assert_difference "TeamMembership.count", -1 do
      delete team_membership_path(membership)
    end
    assert_redirected_to team_path
  end

  test "destroy only affects the current manager's memberships" do
    other = User.create!(email: "other@test.com", name: "Other", password: "password", role: "manager")
    foreign = other.team_memberships.create!(csr_name: "Someone")
    assert_raises(ActiveRecord::RecordNotFound) do
      delete team_membership_path(foreign)
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they fail**

Run: `bin/rails test test/controllers/team_memberships_controller_test.rb -v`
Expected: FAIL — controller/route/component missing.

- [ ] **Step 5: Create the controller**

Create `app/controllers/team_memberships_controller.rb`:

```ruby
class TeamMembershipsController < ApplicationController
  before_action :require_manager

  def index
    render Team::IndexComponent.new(
      memberships: current_user.team_memberships.order(:csr_name),
      csr_suggestions: FeedbackSubmission.distinct.pluck(:csr_name).compact.sort
    )
  end

  def create
    membership = current_user.team_memberships.new(csr_name: params[:csr_name].to_s.strip)

    if membership.save
      redirect_to team_path, notice: "#{membership.csr_name} added to your team."
    else
      redirect_to team_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership = current_user.team_memberships.find(params[:id])
    membership.destroy
    redirect_to team_path, notice: "Removed #{membership.csr_name} from your team."
  end
end
```

- [ ] **Step 6: Create the Team::IndexComponent**

Create `app/views/components/team/index_component.rb`:

```ruby
# frozen_string_literal: true

module Team
  class IndexComponent < ApplicationComponent
    def initialize(memberships:, csr_suggestions:)
      @memberships = memberships
      @csr_suggestions = csr_suggestions
    end

    def view_template
      div(class: "space-y-6", data: { controller: "toggle" }) do
        render_header
        render_team_list
        render_add_form
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "page-title") { "My Team" }
        button(
          type: "button",
          class: "btn btn-primary btn-sm",
          data: { action: "toggle#toggle" }
        ) { "Add team member" }
      end
    end

    def render_team_list
      Card class: "surface" do |card|
        card.body do
          h2(class: "card-title text-lg font-bold mb-4") { "Team list" }
          if @memberships.empty?
            p(class: "text-base-content/60") do
              plain "No CSRs yet. You currently see all feedback. Add a CSR to scope your view."
            end
          else
            ul(class: "space-y-2") do
              @memberships.each { |m| render_member_row(m) }
            end
          end
        end
      end
    end

    def render_member_row(membership)
      li(class: "flex items-center justify-between p-2 rounded bg-base-200") do
        span(class: "font-medium") { membership.csr_name }
        form(action: team_membership_path(membership), method: "post", class: "inline") do
          input(type: "hidden", name: "_method", value: "delete")
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          button(type: "submit", class: "btn btn-ghost btn-xs text-error") { "Remove" }
        end
      end
    end

    def render_add_form
      div(class: "hidden", data: { toggle_target: "panel" }) do
        form(action: team_memberships_path, method: "post", class: "flex gap-2 items-end") do
          input(type: "hidden", name: "authenticity_token", value: form_authenticity_token)
          div(class: "form-control flex-1") do
            label(class: "label") { span(class: "label-text text-sm") { "CSR name" } }
            input(
              type: "text",
              name: "csr_name",
              list: "csr_suggestions",
              placeholder: "Start typing a CSR name…",
              class: "input input-bordered input-sm w-full"
            )
            datalist(id: "csr_suggestions") do
              @csr_suggestions.each { |name| option(value: name) }
            end
          end
          Button(:primary, :sm, type: "submit") { "Save" }
        end
      end
    end
  end
end
```

- [ ] **Step 7: Create the toggle Stimulus controller**

Check whether `app/javascript/controllers/toggle_controller.js` exists. If not, create it:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }
}
```

- [ ] **Step 8: Run tests to verify they pass**

Run: `bin/rails test test/controllers/team_memberships_controller_test.rb -v`
Expected: PASS (all).

- [ ] **Step 9: Add the nav link (managers only)**

In `app/views/components/layouts/application_layout.rb`, add a nav item alongside the existing feedback link (~line 87), guarded by `current_user&.manager?`. Mirror the existing item markup:

```ruby
            if current_user&.manager?
              menu.item do
                a(href: team_path, class: "flex items-center gap-2") do
                  render_icon("M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4z")
                  plain "My Team"
                end
              end
            end
```

(Place this within the same `menu`/`nav` structure that holds the Feedback/Tools/Articles links; match the surrounding indentation and `menu.item`/`a` pattern exactly as used there.)

- [ ] **Step 10: Verify the page renders in the running server**

Run: `bin/rails test test/controllers/team_memberships_controller_test.rb -v` (re-run to confirm the nav change didn't break rendering).
Expected: PASS.

- [ ] **Step 11: Commit**

```bash
git add config/routes.rb app/controllers/application_controller.rb app/controllers/team_memberships_controller.rb app/views/components/team/index_component.rb app/views/components/layouts/application_layout.rb test/controllers/team_memberships_controller_test.rb
git add app/javascript/controllers/toggle_controller.js 2>/dev/null || true
git commit -m "feat: add manager team configuration UI"
```

---

### Task 4: Team-scoped feedback and dashboard views

**Files:**
- Modify: `app/controllers/application_controller.rb` (`team_scoped` helper)
- Modify: `app/controllers/feedback_controller.rb:2-12`
- Modify: `app/controllers/hub_controller.rb`
- Test: `test/controllers/feedback_controller_test.rb`, `test/controllers/hub_controller_test.rb`

**Interfaces:**
- Consumes: `current_user.manager?`, `current_user.team_scoped?`, `current_user.team_csr_names`, `FeedbackSubmission.for_csrs` (Tasks 1–2).
- Produces: `ApplicationController#team_scoped(relation)` → scoped or original relation.

- [ ] **Step 1: Write failing controller tests**

In `test/controllers/feedback_controller_test.rb`, add before the final `end`:

```ruby
  test "manager with a team sees only team feedback" do
    sign_in_as_manager
    get feedback_index_path
    assert_response :success
    assert_select "td a.link-primary", text: "Jane Doe", minimum: 1
  end

  test "manager cannot widen scope with csr param" do
    off = FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team", priority: "High" }
    )
    sign_in_as_manager
    get feedback_index_path(csr: "Off Team")
    assert_response :success
    assert_select "a.link-primary", text: "Off Team", count: 0
  end
```

In `test/controllers/hub_controller_test.rb`, add before the final `end`:

```ruby
  test "manager dashboard counts are team-scoped" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team", priority: "High" }
    )
    sign_in_as_manager
    get hub_path
    assert_response :success
    # Jane Doe fixtures: 1 High, 1 Low for the team; the Off Team High must be excluded.
    assert_select "#metric_cards", text: /1/
  end

  test "manager recent activity is feedback-only" do
    sign_in_as_manager
    get hub_path
    assert_response :success
    assert_select ".badge", text: "Article", count: 0
  end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/feedback_controller_test.rb test/controllers/hub_controller_test.rb -v`
Expected: FAIL — managers currently see all feedback / mixed activity.

- [ ] **Step 3: Add the team_scoped helper**

In `app/controllers/application_controller.rb`, add in the `private` section:

```ruby
  def team_scoped(relation)
    if current_user&.team_scoped?
      relation.for_csrs(current_user.team_csr_names)
    else
      relation
    end
  end
```

- [ ] **Step 4: Scope the feedback index**

In `app/controllers/feedback_controller.rb`, change `index` so the team scope is the base relation:

```ruby
  def index
    @submissions = team_scoped(FeedbackSubmission.includes(:feedback_template)).order(created_at: :desc)
    @submissions = @submissions.where(csr_name: params[:csr]) if params[:csr].present?
    @submissions = @submissions.where(submitted_by: params[:submitted_by]) if params[:submitted_by].present?
    @submissions = @submissions.search(params[:q]) if params[:q].present?

    render Feedback::IndexComponent.new(
      submissions: @submissions,
      filters: { q: params[:q], csr: params[:csr], submitted_by: params[:submitted_by] }
    )
  end
```

- [ ] **Step 5: Scope the dashboard**

Replace `app/controllers/hub_controller.rb` with:

```ruby
class HubController < ApplicationController
  def index
    scope = team_scoped(FeedbackSubmission.all)

    render Dashboard::IndexComponent.new(
      high_count: scope.high_priority.count,
      medium_count: scope.medium_priority.count,
      low_count: scope.low_priority.count,
      total_count: scope.count,
      recent_activity: recent_activity(scope)
    )
  end

  private

  def recent_activity(scope)
    if current_user&.team_scoped?
      scope.includes(:feedback_template).order(created_at: :desc).limit(20).map do |s|
        { type: :feedback, record: s, created_at: s.created_at }
      end
    else
      mixed_recent_activity
    end
  end

  def mixed_recent_activity
    items = []

    FeedbackSubmission.includes(:feedback_template).order(created_at: :desc).limit(20).each do |s|
      items << { type: :feedback, record: s, created_at: s.created_at }
    end

    Article.includes(:author).order(created_at: :desc).limit(20).each do |a|
      items << { type: :article, record: a, created_at: a.created_at }
    end

    Update.includes(:author).order(created_at: :desc).limit(20).each do |u|
      items << { type: :update, record: u, created_at: u.created_at }
    end

    items.sort_by { |i| i[:created_at] }.reverse.first(20)
  end
end
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/feedback_controller_test.rb test/controllers/hub_controller_test.rb -v`
Expected: PASS (all). If the `#metric_cards` text assertion is brittle against fixture data, assert on the rendered count for the team (2 total: high + low) instead.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/application_controller.rb app/controllers/feedback_controller.rb app/controllers/hub_controller.rb test/controllers/feedback_controller_test.rb test/controllers/hub_controller_test.rb
git commit -m "feat: scope feedback and dashboard views to manager team"
```

---

### Task 5: Per-manager real-time broadcasts

**Files:**
- Modify: `app/views/components/dashboard/metric_cards_fragment.rb` (accept a scope)
- Modify: `app/models/feedback_submission.rb` (`broadcast_updates`)
- Modify: `app/views/components/dashboard/index_component.rb:24` (subscribe via `stream_for`)
- Modify: `app/views/components/feedback/index_component.rb:14` (subscribe via `stream_for`)
- Test: `test/models/feedback_submission_test.rb`

**Interfaces:**
- Consumes: `User.managers_for(csr_name)`, `User#stream_for`, `User#team_csr_names`, `FeedbackSubmission.for_csrs` (Tasks 1–2); `current_user` in components.
- Produces: `Dashboard::MetricCardsFragment.new(scope: FeedbackSubmission.all)` (default keeps global counts).

- [ ] **Step 1: Write a failing broadcast test**

In `test/models/feedback_submission_test.rb`, add before the final `end`:

```ruby
  test "broadcasts to the per-manager channel for matching CSRs" do
    manager = users(:manager) # team includes "Jane Doe"
    streams = capture_turbo_stream_broadcasts("dashboard:#{manager.id}") do
      FeedbackSubmission.create!(
        feedback_template: feedback_templates(:csr_feedback),
        data: { csr: "Jane Doe", priority: "High" }
      )
    end
    assert streams.any?, "expected a broadcast to the manager's channel"
  end

  test "does not broadcast off-team feedback to the manager channel" do
    manager = users(:manager)
    streams = capture_turbo_stream_broadcasts("dashboard:#{manager.id}") do
      FeedbackSubmission.create!(
        feedback_template: feedback_templates(:csr_feedback),
        data: { csr: "Someone Else", priority: "High" }
      )
    end
    assert_empty streams
  end
```

> `capture_turbo_stream_broadcasts` is provided by `turbo-rails` test helpers. If it is not available in this app's test setup, assert instead on `Turbo::StreamsChannel.broadcasting_for("dashboard:#{manager.id}")` via `assert_broadcasts(stream, 1) { ... }` from `ActionCable::TestHelper` (include it in the test class). Confirm which helper resolves before implementing; do not leave the assertion abstract.

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/feedback_submission_test.rb -v`
Expected: FAIL — no per-manager broadcast yet.

- [ ] **Step 3: Make MetricCardsFragment scope-aware**

Replace `app/views/components/dashboard/metric_cards_fragment.rb`:

```ruby
# frozen_string_literal: true

module Dashboard
  class MetricCardsFragment < ApplicationComponent
    def initialize(scope: FeedbackSubmission.all)
      @scope = scope
    end

    def view_template
      div(id: "metric_cards", class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4") do
        render MetricCardComponent.new(title: "High Priority", count: @scope.high_priority.count, modifier: :error)
        render MetricCardComponent.new(title: "Medium Priority", count: @scope.medium_priority.count, modifier: :warning)
        render MetricCardComponent.new(title: "Low Priority", count: @scope.low_priority.count, modifier: :success)
        render MetricCardComponent.new(title: "Total Feedbacks", count: @scope.count, modifier: :info)
      end
    end
  end
end
```

- [ ] **Step 4: Fan out broadcasts per manager**

Replace `broadcast_updates` in `app/models/feedback_submission.rb`:

```ruby
  def broadcast_updates
    card = ApplicationController.render(Feedback::CardComponent.new(submission: self))
    activity = ApplicationController.render(Dashboard::ActivityItemComponent.new(item: self, type: :feedback))

    # Global channels: admins, regular users, empty-team managers.
    broadcast_prepend_to "feedback_submissions", target: "submissions", html: card
    broadcast_replace_to "dashboard", target: "metric_cards",
      html: ApplicationController.render(Dashboard::MetricCardsFragment.new)
    broadcast_prepend_to "dashboard", target: "recent_activity", html: activity

    # Per-manager channels: only managers whose team includes this CSR.
    User.managers_for(csr_name).each do |manager|
      scope = FeedbackSubmission.for_csrs(manager.team_csr_names)
      broadcast_prepend_to "feedback_submissions:#{manager.id}", target: "submissions", html: card
      broadcast_replace_to "dashboard:#{manager.id}", target: "metric_cards",
        html: ApplicationController.render(Dashboard::MetricCardsFragment.new(scope: scope))
      broadcast_prepend_to "dashboard:#{manager.id}", target: "recent_activity", html: activity
    end
  end
```

- [ ] **Step 5: Subscribe pages to the right channel**

In `app/views/components/dashboard/index_component.rb`, change the `view_template` subscription line:

```ruby
      turbo_stream_from(current_user&.stream_for("dashboard") || "dashboard")
```

In `app/views/components/feedback/index_component.rb`, change the subscription line:

```ruby
      turbo_stream_from(current_user&.stream_for("feedback_submissions") || "feedback_submissions")
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/models/feedback_submission_test.rb -v`
Expected: PASS (all).

- [ ] **Step 7: Run the controller suite to confirm rendering still works**

Run: `bin/rails test test/controllers/hub_controller_test.rb test/controllers/feedback_controller_test.rb -v`
Expected: PASS — components still render with the new subscription expression.

- [ ] **Step 8: Commit**

```bash
git add app/views/components/dashboard/metric_cards_fragment.rb app/models/feedback_submission.rb app/views/components/dashboard/index_component.rb app/views/components/feedback/index_component.rb test/models/feedback_submission_test.rb
git commit -m "feat: broadcast feedback to per-manager turbo streams"
```

---

### Task 6: Daily digest email

**Files:**
- Modify: `app/mailers/application_mailer.rb` (configurable from address)
- Create: `app/mailers/manager_digest_mailer.rb`
- Create: `app/views/manager_digest_mailer/daily.html.erb`
- Create: `app/views/manager_digest_mailer/daily.text.erb`
- Create: `app/jobs/daily_digest_job.rb`
- Modify: `config/recurring.yml`
- Modify: `config/environments/production.rb` (SMTP from ENV)
- Create: `test/mailers/manager_digest_mailer_test.rb`
- Create: `test/jobs/daily_digest_job_test.rb`

**Interfaces:**
- Consumes: `User.where(role: "manager")`, `User#team_csr_names`, `User#last_digest_sent_at`, `FeedbackSubmission.for_csrs` (Tasks 1–2).
- Produces: `ManagerDigestMailer.daily(manager, submissions)`; `DailyDigestJob.perform_now`.

- [ ] **Step 1: Write failing mailer test**

Create `test/mailers/manager_digest_mailer_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ManagerDigestMailerTest < ActionMailer::TestCase
  test "daily addresses the manager and lists submissions" do
    manager = users(:manager)
    submissions = FeedbackSubmission.for_csrs(manager.team_csr_names)
    email = ManagerDigestMailer.daily(manager, submissions)

    assert_equal [manager.email], email.to
    assert_match "Jane Doe", email.body.encoded
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/mailers/manager_digest_mailer_test.rb -v`
Expected: FAIL — `ManagerDigestMailer` undefined.

- [ ] **Step 3: Create the mailer**

Create `app/mailers/manager_digest_mailer.rb`:

```ruby
class ManagerDigestMailer < ApplicationMailer
  def daily(manager, submissions)
    @manager = manager
    @submissions = submissions
    mail(to: manager.email, subject: "Your daily feedback digest (#{submissions.size} new)")
  end
end
```

- [ ] **Step 4: Create the mailer views**

Create `app/views/manager_digest_mailer/daily.html.erb`:

```erb
<h1>Daily feedback digest</h1>
<p>Hi <%= @manager.name %>, here is new feedback for your team since your last digest:</p>
<ul>
  <% @submissions.each do |s| %>
    <li>
      <strong><%= s.csr_name %></strong>
      — <%= s.priority || "—" %> / <%= s.feedback_type || "—" %>
      (ticket <%= s.ticket_number || "—" %>, submitted by <%= s.submitted_by || "—" %>)
      on <%= s.created_at.strftime("%b %d, %Y %H:%M") %>
    </li>
  <% end %>
</ul>
```

Create `app/views/manager_digest_mailer/daily.text.erb`:

```erb
Daily feedback digest

Hi <%= @manager.name %>, here is new feedback for your team since your last digest:

<% @submissions.each do |s| -%>
- <%= s.csr_name %> — <%= s.priority || "—" %> / <%= s.feedback_type || "—" %> (ticket <%= s.ticket_number || "—" %>, by <%= s.submitted_by || "—" %>) on <%= s.created_at.strftime("%b %d, %Y %H:%M") %>
<% end -%>
```

- [ ] **Step 5: Run mailer test to verify it passes**

Run: `bin/rails test test/mailers/manager_digest_mailer_test.rb -v`
Expected: PASS.

- [ ] **Step 6: Write failing job test**

Create `test/jobs/daily_digest_job_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class DailyDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "emails a manager with new team feedback and advances the watermark" do
    manager = users(:manager) # team: "Jane Doe", has fixture feedback
    manager.update!(last_digest_sent_at: 1.day.ago)

    assert_emails 1 do
      DailyDigestJob.perform_now
    end
    assert_not_nil manager.reload.last_digest_sent_at
    assert_operator manager.last_digest_sent_at, :>, 1.minute.ago
  end

  test "skips a manager with no new feedback" do
    manager = users(:manager)
    manager.update!(last_digest_sent_at: Time.current)

    assert_no_emails do
      DailyDigestJob.perform_now
    end
  end

  test "skips an empty-team manager (never a firehose)" do
    empty = User.create!(email: "empty2@test.com", name: "Empty", password: "password", role: "manager")
    assert_no_emails do
      DailyDigestJob.perform_now
    end
    assert_nil empty.reload.last_digest_sent_at
  end
end
```

> Fixtures provide `users(:manager)` with `last_digest_sent_at` nil by default; the first test sets it to `1.day.ago` so the fixture feedback (created at load time) counts as "since". If fixture `created_at` predates that, set `last_digest_sent_at` to `1.year.ago` instead so fixture rows qualify.

- [ ] **Step 7: Run job test to verify it fails**

Run: `bin/rails test test/jobs/daily_digest_job_test.rb -v`
Expected: FAIL — `DailyDigestJob` undefined.

- [ ] **Step 8: Create the job**

Create `app/jobs/daily_digest_job.rb`:

```ruby
class DailyDigestJob < ApplicationJob
  queue_as :default

  def perform
    User.where(role: "manager").find_each do |manager|
      names = manager.team_csr_names
      next if names.empty?

      since = manager.last_digest_sent_at || manager.created_at
      submissions = FeedbackSubmission.for_csrs(names)
        .where("created_at > ?", since)
        .order(created_at: :desc)
      next if submissions.empty?

      begin
        ManagerDigestMailer.daily(manager, submissions).deliver_now
        manager.update!(last_digest_sent_at: Time.current)
      rescue => e
        Rails.logger.error("DailyDigestJob failed for manager #{manager.id}: #{e.message}")
      end
    end
  end
end
```

- [ ] **Step 9: Run job test to verify it passes**

Run: `bin/rails test test/jobs/daily_digest_job_test.rb -v`
Expected: PASS (all).

- [ ] **Step 10: Schedule the recurring job**

In `config/recurring.yml`, under `production:`, add:

```yaml
  daily_manager_digest:
    class: DailyDigestJob
    schedule: at 8am every day
```

- [ ] **Step 11: Configure SMTP from environment (no hardcoded credentials)**

In `app/mailers/application_mailer.rb`, change the default from address:

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@feedbackhub.local")
  layout "mailer"
end
```

In `config/environments/production.rb`, add ActionMailer SMTP config reading from ENV (place inside the `Rails.application.configure do` block):

```ruby
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }
```

(Operator supplies `SMTP_ADDRESS`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_PORT`, `MAILER_FROM` at deploy. Do not commit credentials.)

- [ ] **Step 12: Run the mailer + job suites once more**

Run: `bin/rails test test/mailers/manager_digest_mailer_test.rb test/jobs/daily_digest_job_test.rb -v`
Expected: PASS.

- [ ] **Step 13: Commit**

```bash
git add app/mailers/application_mailer.rb app/mailers/manager_digest_mailer.rb app/views/manager_digest_mailer/ app/jobs/daily_digest_job.rb config/recurring.yml config/environments/production.rb test/mailers/manager_digest_mailer_test.rb test/jobs/daily_digest_job_test.rb
git commit -m "feat: add daily manager feedback digest email"
```

---

### Task 7: Full-suite verification

**Files:** none (verification only).

- [ ] **Step 1: Run the entire test suite**

Run: `bin/rails test`
Expected: PASS — all model, controller, mailer, and job tests green, no regressions in existing suites.

- [ ] **Step 2: Manual smoke (optional, against the running dev server)**

- Sign in as an admin, set a user's role to `manager` via `/admin/users`.
- Sign in as that manager, visit `/team`, add and remove a CSR via the datalist-backed form.
- Confirm `/` and `/feedback` show only that CSR's feedback; an empty team shows everything.

- [ ] **Step 3: Commit any test-only fixes**

```bash
git add -A
git commit -m "test: stabilize manager teams suite" || echo "nothing to commit"
```

---

## Self-Review Notes

- **Spec coverage:** role (Task 1) · team_memberships + watermark + scopes (Task 2) · team UI/routes/nav/auth (Task 3) · view scoping incl. param-can't-widen + feedback-only activity + scoped counts (Task 4) · per-manager realtime with shared `managers_for` query + scoped metric fragment (Task 5) · daily digest mailer/job/schedule + empty-team-skip + SMTP-from-ENV (Task 6). All spec sections map to a task.
- **Empty-team trap:** digest uses `for_csrs(names)` with explicit `next if names.empty?` — never the view fallback (Task 6, Step 8; tested Task 6, Step 6 third test).
- **Case-insensitivity:** `for_csrs`, `managers_for`, and `TeamMembership` uniqueness all normalize via `LOWER`/`case_sensitive: false`.
- **Naming consistency:** `stream_for(base)` ⇒ `"#{base}:#{id}"` matches broadcast targets `"dashboard:#{manager.id}"` / `"feedback_submissions:#{manager.id}"`.
