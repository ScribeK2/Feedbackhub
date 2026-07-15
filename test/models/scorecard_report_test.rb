# frozen_string_literal: true

require "test_helper"

class ScorecardReportTest < ActiveSupport::TestCase
  include ScorecardTestHelper

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

  test "status_counts tallies the current period by status" do
    template = feedback_templates(:csr_feedback)
    Csr.lookup("Status CSR") || Csr.create!(name: "Status CSR")
    FeedbackSubmission.create!(feedback_template: template,
      data: { "csr" => "Status CSR", "priority" => "High" })
    closed = FeedbackSubmission.create!(feedback_template: template,
      data: { "csr" => "Status CSR", "priority" => "Low" })
    closed.update!(status: "actioned")

    report = ScorecardReport.new(csr_name: "Status CSR")
    assert_equal({ "open" => 1, "reviewed" => 0, "actioned" => 1, "dismissed" => 0 }, report.status_counts)
  end

  test "open_count counts open items across all time" do
    template = feedback_templates(:csr_feedback)
    Csr.lookup("Status CSR") || Csr.create!(name: "Status CSR")
    old = FeedbackSubmission.create!(feedback_template: template,
      data: { "csr" => "Status CSR", "priority" => "High" })
    old.update_columns(created_at: 2.years.ago)
    FeedbackSubmission.create!(feedback_template: template,
      data: { "csr" => "Status CSR", "priority" => "Low" })

    report = ScorecardReport.new(csr_name: "Status CSR")
    assert_equal 2, report.open_count
  end

  test "for_team aggregates counts across every CSR in the set" do
    range = (10.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Team A", created_at: 2.days.ago)
    build_submission(csr: "Team B", created_at: 3.days.ago)
    build_submission(csr: "Team B", created_at: 4.days.ago)
    build_submission(csr: "Off The Team", created_at: 2.days.ago)

    report = ScorecardReport.for_team([ "Team A", "Team B" ], date_range: range)

    assert_equal 3, report.total_count
  end

  test "for_team computes delta across the whole set" do
    range = (10.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Team A", created_at: 2.days.ago)   # current window
    build_submission(csr: "Team B", created_at: 3.days.ago)   # current window
    build_submission(csr: "Team A", created_at: 15.days.ago)  # previous window

    report = ScorecardReport.for_team([ "Team A", "Team B" ], date_range: range)

    assert_equal 2, report.total_count
    assert_equal 1, report.previous_count
    assert_equal 1, report.delta
  end

  test "for_team matches every name in the set case-insensitively" do
    build_submission(csr: "Mixed Case", created_at: 1.day.ago)
    build_submission(csr: "Other Name", created_at: 1.day.ago)

    report = ScorecardReport.for_team([ "mixed case", "OTHER NAME" ])

    assert_equal 2, report.total_count
  end

  test "for_team with no names counts nothing" do
    build_submission(csr: "Team A", created_at: 1.day.ago)

    report = ScorecardReport.for_team([])

    assert_equal 0, report.total_count
    assert report.empty?
  end

  test "trend_buckets counts without materializing submissions" do
    range = (14.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Pluck CSR", created_at: 2.days.ago)
    report = ScorecardReport.new(csr_name: "Pluck CSR", date_range: range)

    assert_equal 1, report.trend_buckets.sum { |b| b[:count] }
    # The whole point: buckets must not drag full rows (and the JSON blob)
    # through Ruby, so the current_submissions cache stays cold.
    assert_not report.instance_variable_defined?(:@current_submissions)
  end

  test "for_team trend_buckets sums across the set" do
    range = (14.days.ago.beginning_of_day)..(Time.current.end_of_day)
    build_submission(csr: "Team A", created_at: 2.days.ago)
    build_submission(csr: "Team B", created_at: 3.days.ago)

    report = ScorecardReport.for_team([ "Team A", "Team B" ], date_range: range)

    assert_equal 2, report.trend_buckets.sum { |b| b[:count] }
  end

  test "csr_name raises ArgumentError for multi-CSR reports" do
    build_submission(csr: "Team A", created_at: 1.day.ago)
    build_submission(csr: "Team B", created_at: 1.day.ago)

    report = ScorecardReport.for_team([ "Team A", "Team B" ])

    error = assert_raises(ArgumentError) { report.csr_name }
    assert_match(/covers 2/, error.message)
  end

  test "csr_name returns the name for single-CSR reports" do
    build_submission(csr: "Single CSR", created_at: 1.day.ago)

    report = ScorecardReport.new(csr_name: "Single CSR")

    assert_equal "Single CSR", report.csr_name
  end
end
