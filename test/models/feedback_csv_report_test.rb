# frozen_string_literal: true

require "test_helper"

class FeedbackCsvReportTest < ActiveSupport::TestCase
  test "renders a header row" do
    csv = FeedbackCsvReport.new([]).to_csv
    assert_equal "id,created_at,template,csr_name,feedback_type,priority,status,ticket_number,submitted_by",
                 csv.lines.first.chomp
  end

  test "renders one data row per submission" do
    submissions = [ feedback_submissions(:high_priority), feedback_submissions(:low_priority) ]
    rows = CSV.parse(FeedbackCsvReport.new(submissions).to_csv, headers: true)
    assert_equal 2, rows.length
    assert_equal "TK-001", rows.first["ticket_number"]
    assert_equal "Jane Doe", rows.first["csr_name"]
    assert_equal "High", rows.first["priority"]
    assert_equal "csr_feedback", rows.first["template"]
  end

  test "empty collection yields header only" do
    assert_equal 1, FeedbackCsvReport.new([]).to_csv.lines.length
  end

  test "escapes commas and quotes in values" do
    submission = feedback_submissions(:high_priority)
    submission.csr_name = 'Doe, "Jane"'
    csv = FeedbackCsvReport.new([ submission ]).to_csv
    row = CSV.parse(csv, headers: true).first
    assert_equal 'Doe, "Jane"', row["csr_name"]
  end

  test "filename includes today's date" do
    assert_equal "feedback-#{Date.current.iso8601}.csv", FeedbackCsvReport.new([]).filename
  end
end
