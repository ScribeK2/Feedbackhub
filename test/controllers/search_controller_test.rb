# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
  end

  test "search with query returns results" do
    get search_path(q: "Jane Doe")
    assert_response :success
  end

  test "search with empty query returns empty" do
    get search_path(q: "")
    assert_response :success
  end

  test "search finds feedbacks" do
    get search_path(q: "TK-001")
    assert_response :success
  end

  test "search finds articles" do
    get search_path(q: "DNS")
    assert_response :success
  end

  test "search with no matches returns empty" do
    get search_path(q: "zzz_nothing_here_zzz")
    assert_response :success
  end

  test "unauthenticated user is redirected" do
    delete logout_path
    get search_path(q: "test")
    assert_redirected_to login_path
  end

  test "global search finds feedback by comment text with a labeled snippet" do
    SearchEntry.rebuild!
    Comment.create!(feedback_submission: feedback_submissions(:high_priority),
      author: users(:regular), body: "the refund was reissued twice")
    sign_in_as_user
    get search_path(q: "reissued"), as: :turbo_stream
    assert_response :success
    assert_match "in comment", response.body
    assert_match "<mark", response.body
    assert_match "reissued", response.body
  end

  test "global search escapes HTML living in indexed content" do
    SearchEntry.rebuild!
    Comment.create!(feedback_submission: feedback_submissions(:high_priority),
      author: users(:regular), body: "beware <script>alert(1)</script> injection")
    sign_in_as_user
    get search_path(q: "injection"), as: :turbo_stream
    assert_response :success
    assert_no_match "<script>alert(1)</script>", response.body
  end

  test "global search team-scopes feedback results for managers" do
    SearchEntry.rebuild!
    off_team = FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { "ticket_number" => "TK-OFF", "csr" => "Off Team Person", "feedback_type" => "Knowledge Gap",
              "impact" => "Resolution Time", "priority" => "High", "submitted_by" => "Leak Check" }
    )
    Comment.create!(feedback_submission: off_team, author: users(:regular), body: "confidential offteam detail")

    sign_in_as_manager
    get search_path(q: "TK-OFF"), as: :turbo_stream
    assert_no_match "TK-OFF", response.body

    get search_path(q: "offteam"), as: :turbo_stream
    assert_no_match "TK-OFF", response.body

    sign_in_as_admin
    get search_path(q: "TK-OFF"), as: :turbo_stream
    assert_match "TK-OFF", response.body
  end
end
