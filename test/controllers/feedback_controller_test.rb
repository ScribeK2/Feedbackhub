# frozen_string_literal: true

require "test_helper"

class FeedbackControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as_user
    @template = feedback_templates(:csr_feedback)
  end

  # Index
  test "index renders feedbacks list" do
    get feedback_index_path
    assert_response :success
  end

  test "index filters by csr" do
    get feedback_index_path(csr: "Jane Doe")
    assert_response :success
  end

  test "index filters by submitted_by" do
    get feedback_index_path(submitted_by: "John Smith")
    assert_response :success
  end

  test "index filters by search query" do
    get feedback_index_path(q: "TK-001")
    assert_response :success
  end

  # New/Create
  test "new renders feedback form" do
    get new_feedback_path
    assert_response :success
  end

  test "new with template_id preselects template" do
    get new_feedback_path(template_id: @template.id)
    assert_response :success
  end

  test "create saves valid submission and redirects" do
    assert_difference "FeedbackSubmission.count", 1 do
      post feedback_index_path, params: {
        feedback_template_id: @template.id,
        data: {
          ticket_number: "TK-100",
          csr: "Test CSR",
          feedback_type: "Knowledge Gap",
          impact: "Resolution Time",
          priority: "High",
          submitted_by: "Tester"
        }
      }
    end
    assert_redirected_to hub_path
  end

  test "create via turbo stream returns success component" do
    post feedback_index_path, params: {
      feedback_template_id: @template.id,
      data: {
        ticket_number: "TK-101",
        csr: "CSR",
        feedback_type: "Other",
        impact: "Other",
        priority: "Low",
        submitted_by: "Tester"
      }
    }, as: :turbo_stream
    assert_response :success
  end

  test "create with missing data re-renders form" do
    post feedback_index_path, params: {
      feedback_template_id: @template.id
    }
    assert_response :unprocessable_entity
  end

  # Show
  test "show renders submission modal" do
    submission = feedback_submissions(:high_priority)
    get feedback_path(submission)
    assert_response :success
  end

  # Form
  test "form action returns turbo stream with template fields" do
    get form_feedback_index_path(template_id: @template.id), as: :turbo_stream
    assert_response :success
  end

  test "form action without template_id shows placeholder" do
    get form_feedback_index_path, as: :turbo_stream
    assert_response :success
  end

  # Auth
  test "unauthenticated user is redirected to login" do
    delete logout_path
    get feedback_index_path
    assert_redirected_to login_path
  end

  test "manager with a team sees only team feedback" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team Person", priority: "High" }
    )
    sign_in_as_manager
    get feedback_index_path
    assert_response :success
    assert_select "td a.link-primary", text: "Jane Doe", minimum: 1
    assert_select "a.link-primary", text: "Off Team Person", count: 0
  end

  test "manager cannot widen scope with csr param" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      data: { csr: "Off Team", priority: "High" }
    )
    sign_in_as_manager
    get feedback_index_path(csr: "Off Team")
    assert_response :success
    assert_select "a.link-primary", text: "Off Team", count: 0
  end

  test "index shows a status column with badges" do
    sign_in_as_user
    get feedback_index_path
    assert_response :success
    assert_select "th", text: "Status"
    assert_select "#submission_row_#{feedback_submissions(:high_priority).id} .badge", text: "Open"
  end

  test "show renders triage controls for the team manager" do
    sign_in_as_manager
    get feedback_path(feedback_submissions(:high_priority))
    assert_response :success
    assert_match "Mark Reviewed", response.body
  end

  test "show hides triage controls from regular users but keeps the status section" do
    sign_in_as_user
    get feedback_path(feedback_submissions(:high_priority))
    assert_response :success
    assert_no_match "Mark Reviewed", response.body
    assert_match "triage_submission_#{feedback_submissions(:high_priority).id}", response.body
  end

  test "show renders the status timeline" do
    submission = feedback_submissions(:high_priority)
    submission.transition_to("reviewed", actor: users(:manager))

    sign_in_as_manager
    get feedback_path(submission)
    assert_match "marked reviewed", response.body
    assert_match users(:manager).name, response.body
  end

  test "index filters by status" do
    feedback_submissions(:low_priority).update!(status: "dismissed")

    sign_in_as_user
    get feedback_index_path(status: "open")
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-002", response.body
  end

  test "index filters by priority" do
    sign_in_as_user
    get feedback_index_path(priority: "High")
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-002", response.body
  end

  test "create rejects an unregistered CSR" do
    assert_no_difference "FeedbackSubmission.count" do
      post feedback_index_path, params: {
        feedback_template_id: @template.id,
        data: {
          ticket_number: "TK-999",
          csr: "Ghost Person",
          feedback_type: "Knowledge Gap",
          impact: "Resolution Time",
          priority: "High",
          submitted_by: "Tester"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "form renders csr field as a select of active registered CSRs" do
    get new_feedback_path(template_id: @template.id)
    assert_response :success
    assert_select "select[name='data[csr]']" do
      assert_select "option[value='Jane Doe']"
      assert_select "option[value='Former Employee']", false
    end
  end

  test "non-admin cannot edit feedback" do
    sign_in_as_user
    get edit_feedback_path(feedback_submissions(:high_priority))
    assert_redirected_to root_path
  end

  test "admin edit renders the prefilled form" do
    sign_in_as_admin
    get edit_feedback_path(feedback_submissions(:high_priority))
    assert_response :success
    assert_match 'value="TK-001"', response.body
    assert_match "Edit Feedback", response.body
  end

  test "admin can correct the CSR and grouping fields re-sync" do
    sign_in_as_admin
    submission = feedback_submissions(:high_priority)

    patch feedback_path(submission), params: {
      feedback_template_id: submission.feedback_template_id,
      data: {
        ticket_number: "TK-001",
        csr: "Test CSR",
        feedback_type: "Knowledge Gap",
        impact: "Resolution Time",
        priority: "Medium",
        submitted_by: "John Smith"
      }
    }
    assert_redirected_to feedback_index_path
    submission.reload
    assert_equal "Test CSR", submission.csr_name
    assert_equal "Test CSR", submission.data["csr"]
    assert_equal "Medium", submission.priority
  end

  test "update with an unregistered CSR re-renders the form" do
    sign_in_as_admin
    submission = feedback_submissions(:high_priority)

    patch feedback_path(submission), params: {
      feedback_template_id: submission.feedback_template_id,
      data: {
        ticket_number: "TK-001",
        csr: "Nobody Registered",
        feedback_type: "Knowledge Gap",
        impact: "Resolution Time",
        priority: "High",
        submitted_by: "John Smith"
      }
    }
    assert_response :unprocessable_entity
    assert_equal "Jane Doe", feedback_submissions(:high_priority).reload.csr_name
  end

  test "non-admin cannot update feedback" do
    sign_in_as_user
    patch feedback_path(feedback_submissions(:high_priority)), params: {
      data: { csr: "Test CSR" }
    }
    assert_redirected_to root_path
    assert_equal "Jane Doe", feedback_submissions(:high_priority).reload.csr_name
  end

  test "admin can destroy feedback with its dependents" do
    sign_in_as_admin
    submission = feedback_submissions(:high_priority)
    submission.comments.create!(author: users(:regular), body: "Will cascade")

    assert_difference [ "FeedbackSubmission.count", "Comment.count" ], -1 do
      delete feedback_path(submission)
    end
    assert_redirected_to feedback_index_path
  end

  test "non-admin cannot destroy feedback" do
    sign_in_as_user
    assert_no_difference "FeedbackSubmission.count" do
      delete feedback_path(feedback_submissions(:high_priority))
    end
    assert_redirected_to root_path
  end

  test "failed create re-renders the form with entered values" do
    sign_in_as_user
    post feedback_index_path, params: {
      feedback_template_id: feedback_templates(:csr_feedback).id,
      data: {
        ticket_number: "TK-999",
        csr: "Nobody Registered",
        feedback_type: "Knowledge Gap",
        impact: "Resolution Time",
        priority: "High",
        submitted_by: "Prefill Check"
      }
    }
    assert_response :unprocessable_entity
    assert_match 'value="TK-999"', response.body
    assert_match 'value="Prefill Check"', response.body
  end

  test "index filters by feedback_type" do
    get feedback_index_path(feedback_type: "Knowledge Gap")
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-002", response.body
  end

  test "index filters by date range" do
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      created_at: 100.days.ago, updated_at: 100.days.ago,
      data: {
        "ticket_number" => "TK-ANCIENT", "csr" => "Jane Doe", "feedback_type" => "Knowledge Gap",
        "impact" => "Resolution Time", "priority" => "High", "submitted_by" => "Tester"
      }
    )
    get feedback_index_path(start: 7.days.ago.to_date.iso8601, end: Date.current.iso8601)
    assert_response :success
    assert_match "TK-001", response.body
    assert_no_match "TK-ANCIENT", response.body
  end

  test "index combines csr, priority, and date range" do
    get feedback_index_path(
      csr: "Jane Doe", priority: "High",
      start: 7.days.ago.to_date.iso8601, end: Date.current.iso8601
    )
    assert_response :success
    assert_match "TK-001", response.body   # High, Jane Doe, recent
    assert_no_match "TK-002", response.body # Low — excluded by priority
  end

  test "index ignores garbage dates" do
    get feedback_index_path(start: "not-a-date", end: "also-nope")
    assert_response :success
    assert_match "TK-001", response.body
    assert_match "TK-002", response.body
  end

  test "index ignores an inverted date range" do
    get feedback_index_path(start: Date.current.iso8601, end: 7.days.ago.to_date.iso8601)
    assert_response :success
    assert_match "TK-001", response.body
    assert_match "TK-002", response.body
  end

  test "index filter bar renders date inputs and type select" do
    get feedback_index_path
    assert_response :success
    assert_select "input[type=date][name=start]"
    assert_select "input[type=date][name=end]"
    assert_select "select[name=feedback_type]" do
      assert_select "option", text: "Knowledge Gap"   # rendered as-is, not "Knowledge gap"
      assert_select "option", text: "Process Failure"
    end
  end

  test "index Clear button appears for a date-only filter" do
    get feedback_index_path(start: 7.days.ago.to_date.iso8601, end: Date.current.iso8601)
    assert_response :success
    assert_select "a", text: "Clear"
  end
end
