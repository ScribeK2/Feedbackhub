# frozen_string_literal: true

require "test_helper"

class HubControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "index renders dashboard successfully" do
    get hub_path
    assert_response :success
  end

  test "root path renders dashboard" do
    get root_path
    assert_response :success
  end

  test "unauthenticated user is redirected to login" do
    delete logout_path
    get hub_path
    assert_redirected_to login_path
  end

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

  test "manager dashboard counts are team-scoped" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team Person", priority: "High" }
    )
    sign_in_as_manager
    get hub_path
    assert_response :success
    # Team (Jane Doe): Open High=1, Open Medium=0, Open Low=1, Open Total=2.
    # Off Team Person's High submission must NOT push Open High to 2 or Open Total to 3.
    assert_select "#metric_cards .badge-error", text: "1"   # Open High = 1, not 2
    assert_select "#metric_cards .badge-info",  text: "2"   # Open Total = 2, not 3
  end

  test "manager recent activity is feedback-only" do
    sign_in_as_manager
    get hub_path
    assert_response :success
    assert_select ".badge", text: "Article", count: 0
  end

  test "metric cards count only open items and link to the filtered index" do
    feedback_submissions(:low_priority).update!(status: "actioned")

    sign_in_as_user
    get hub_path
    assert_response :success
    assert_match "Open High Priority", response.body
    assert_select "#metric_cards a[href=?]", feedback_index_path(status: "open", priority: "High")
    # Fixtures: 3 submissions, 1 actioned above => Open Total = 2
    assert_select "#metric_cards .badge-info", text: "2"
  end
end
