# frozen_string_literal: true

require "test_helper"

class ScorecardSummaryCsvReportTest < ActiveSupport::TestCase
  test "renders a header row" do
    csv = ScorecardSummaryCsvReport.new([]).to_csv
    assert_equal "csr_name,total,delta,open,high,medium,low,s_open,s_reviewed,s_actioned,s_dismissed",
                 csv.lines.first.chomp
  end

  test "renders one row per report with metrics and breakdowns" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    rows = CSV.parse(ScorecardSummaryCsvReport.new([ report ]).to_csv, headers: true)
    assert_equal 1, rows.length
    row = rows.first
    assert_equal "Jane Doe", row["csr_name"]
    assert_equal report.total_count.to_s, row["total"]
    assert_equal report.severity_counts["High"].to_s, row["high"]
    assert_equal report.status_counts["open"].to_s, row["s_open"]
  end

  test "empty collection yields header only" do
    assert_equal 1, ScorecardSummaryCsvReport.new([]).to_csv.lines.length
  end

  test "filename includes today's date" do
    assert_equal "scorecards-#{Date.current.iso8601}.csv", ScorecardSummaryCsvReport.new([]).filename
  end

  test "neutralizes formula injection in the csr name" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    report.define_singleton_method(:csr_name) { "=cmd()" }
    row = CSV.parse(ScorecardSummaryCsvReport.new([ report ]).to_csv, headers: true).first
    assert_equal "'=cmd()", row["csr_name"]
  end
end
