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
