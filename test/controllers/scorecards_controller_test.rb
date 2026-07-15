# frozen_string_literal: true

require "test_helper"

class ScorecardsControllerTest < ActionDispatch::IntegrationTest
  include ScorecardTestHelper

  # The `manager` fixture's team includes "Jane Doe" (team_memberships(:manager_jane)),
  # and Jane Doe has two feedback fixtures.

  # A manager whose team is exactly the given CSR names.
  def manager_with_team(email, names)
    manager = User.create!(email: email, name: "Team Mgr", password: "password", role: "manager")
    names.each do |name|
      Csr.lookup(name) || Csr.create!(name: name)
      TeamMembership.create!(manager: manager, csr_name: name)
    end
    manager
  end

  # Default range is the last 30 days, so the previous window is days 30-60.
  def build_movement_team(email)
    manager = manager_with_team(email, %w[Riser Flat Faller])
    2.times { build_submission(csr: "Riser", created_at: 2.days.ago) }   # 0 -> 2, delta +2
    build_submission(csr: "Flat", created_at: 2.days.ago)                # 1 -> 1, delta  0
    build_submission(csr: "Flat", created_at: 45.days.ago)
    2.times { build_submission(csr: "Faller", created_at: 45.days.ago) } # 2 -> 0, delta -2
    manager
  end

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

  test "viewing a CSR with no feedback at all shows the no-data state" do
    sign_in_as_admin
    get scorecard_path(csr: "Ghost CSR")
    assert_response :success
    assert_includes response.body, "No feedback on record"
  end

  test "viewing a CSR whose only issues fall outside the range shows the zero-in-period good state" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      created_at: 200.days.ago, updated_at: 200.days.ago,
      data: {
        "ticket_number" => "TK-OLD", "csr" => "Stale CSR", "feedback_type" => "Knowledge Gap",
        "impact" => "Resolution Time", "priority" => "Low", "submitted_by" => "Tester"
      }
    )
    sign_in_as_admin
    get scorecard_path(csr: "Stale CSR")
    assert_response :success
    assert_includes response.body, "No issues logged"
  end

  test "show renders the follow-through breakdown" do
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe")
    assert_response :success
    assert_match "Follow-through", response.body
  end

  test "index tiles show open counts" do
    sign_in_as_manager
    get scorecards_path
    assert_response :success
    assert_match "2 open", response.body # Jane Doe fixtures: TK-001 + TK-002, both open
  end

  test "show honors explicit start and end params" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      created_at: 200.days.ago, updated_at: 200.days.ago,
      data: {
        "ticket_number" => "TK-OLD-1", "csr" => "Jane Doe", "feedback_type" => "Knowledge Gap",
        "impact" => "Resolution Time", "priority" => "Low", "submitted_by" => "Tester"
      }
    )
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe", start: 205.days.ago.to_date.iso8601, end: 195.days.ago.to_date.iso8601)
    assert_response :success
    # Only the 200-day-old submission is in the window; the 2 recent fixtures are not.
    assert_match ">1<", response.body # total_count of 1 in the volume panel
  end

  test "show falls back to the default range on inverted dates" do
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe", start: Date.current.iso8601, end: 10.days.ago.to_date.iso8601)
    assert_response :success
    assert_match ">2<", response.body # default 30-day window: both Jane Doe fixtures
  end

  test "scorecard breakdown bars deep-link to the filtered feedback index" do
    sign_in_as_manager
    start_param = 30.days.ago.to_date.iso8601
    end_param = Date.current.iso8601
    get scorecard_path(csr: "Jane Doe", start: start_param, end: end_param)
    assert_response :success

    body = CGI.unescapeHTML(response.body)
    # Severity: High has count 1 (TK-001) -> linked with priority param + context
    assert_includes body, "/feedback?csr=Jane+Doe&end=#{end_param}&priority=High&start=#{start_param}"
    # Follow-through: open has count 2 -> linked with status param
    assert_includes body, "/feedback?csr=Jane+Doe&end=#{end_param}&start=#{start_param}&status=open"
    # Category: Knowledge Gap -> linked with feedback_type param
    assert_includes body, "/feedback?csr=Jane+Doe&end=#{end_param}&feedback_type=Knowledge+Gap&start=#{start_param}"
    # Impact: never linked
    assert_not_includes body, "impact="
  end

  test "zero-count breakdown rows are not linked" do
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe")
    body = CGI.unescapeHTML(response.body)
    # Both Jane Doe fixtures are open -> reviewed/actioned/dismissed have count 0
    assert_not_includes body, "status=reviewed"
    assert_not_includes body, "status=actioned"
  end

  # CSV export
  test "index csv requires manager or admin" do
    sign_in_as_user
    get scorecards_path(format: :csv)
    assert_redirected_to root_path
  end

  test "index csv returns team-summary for a manager" do
    sign_in_as_manager
    get scorecards_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/\Acsr_name,total,delta,open/, response.body)
    assert_includes response.body, "Jane Doe" # manager's team
  end

  test "show csv returns a single-CSR detail for an authorized csr" do
    sign_in_as_manager
    get scorecard_path(csr: "Jane Doe", format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/\Asection,label,count/, response.body)
    assert_match(/attachment; filename=/, response.headers["Content-Disposition"])
  end

  test "show csv redirects for a csr not on the manager's team" do
    sign_in_as_manager
    get scorecard_path(csr: "Carlos Reyes", format: :csv)
    assert_redirected_to scorecards_path
  end

  test "index sorts CSRs by signed delta descending" do
    manager = build_movement_team("sort@test.com")
    sign_in(manager)

    get scorecards_path
    assert_response :success

    body = response.body
    assert_operator body.index("Riser"), :<, body.index("Flat")
    assert_operator body.index("Flat"), :<, body.index("Faller")
  end

  test "index breaks delta ties alphabetically" do
    # Neither CSR has any feedback, so both sit at delta 0.
    manager = manager_with_team("tie@test.com", %w[Zeta Alpha])
    sign_in(manager)

    get scorecards_path
    assert_response :success

    body = response.body
    assert_operator body.index("Alpha"), :<, body.index("Zeta")
  end

  test "index honors explicit start and end params" do
    build_submission(csr: "Jane Doe", created_at: 200.days.ago)
    sign_in_as_manager

    get scorecards_path(start: 205.days.ago.to_date.iso8601, end: 195.days.ago.to_date.iso8601)
    assert_response :success
    # Only the 200-day-old item falls in the window; the two recent Jane Doe
    # fixtures do not. Regression guard: HTML used to ignore these params
    # while the CSV honored them.
    assert_match ">1<", response.body
  end

  test "index falls back to the default range on inverted dates" do
    sign_in_as_manager

    get scorecards_path(start: Date.current.iso8601, end: 10.days.ago.to_date.iso8601)
    assert_response :success
    assert_match ">2<", response.body # both Jane Doe fixtures in the default 30-day window
  end

  test "index csv rows follow the same delta order as the page" do
    manager = build_movement_team("csvorder@test.com")
    sign_in(manager)

    get scorecards_path(format: :csv)
    assert_response :success

    rows = CSV.parse(response.body, headers: true)
    assert_equal %w[Riser Flat Faller], rows.map { |row| row["csr_name"] }
  end

  test "index renders the date form populated with the requested range" do
    sign_in_as_manager

    get scorecards_path(start: "2026-01-01", end: "2026-01-31")
    assert_response :success

    assert_includes response.body, 'value="2026-01-01"'
    assert_includes response.body, 'value="2026-01-31"'
  end

  test "index export csv link carries the requested range" do
    sign_in_as_manager
    start_param = 10.days.ago.to_date.iso8601
    end_param = Date.current.iso8601

    get scorecards_path(start: start_param, end: end_param)
    assert_response :success

    body = CGI.unescapeHTML(response.body)
    assert_includes body, "/scorecards.csv?end=#{end_param}&start=#{start_param}"
  end

  test "show still renders its date form after the extraction" do
    sign_in_as_manager

    get scorecard_path(csr: "Jane Doe", start: "2026-01-01", end: "2026-01-31")
    assert_response :success

    assert_includes response.body, 'value="2026-01-01"'
    assert_includes response.body, 'name="csr"' # the show form keeps its hidden CSR field
  end
end
