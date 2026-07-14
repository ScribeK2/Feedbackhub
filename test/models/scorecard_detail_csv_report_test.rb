# frozen_string_literal: true

require "test_helper"

class ScorecardDetailCsvReportTest < ActiveSupport::TestCase
  test "renders a header row" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    csv = ScorecardDetailCsvReport.new(report).to_csv
    assert_equal "section,label,count", csv.lines.first.chomp
  end

  test "includes each breakdown section" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    rows = CSV.parse(ScorecardDetailCsvReport.new(report).to_csv, headers: true)
    sections = rows.map { |r| r["section"] }.uniq
    assert_includes sections, "severity"
    assert_includes sections, "category"
    assert_includes sections, "impact"
    assert_includes sections, "status"
    assert_includes sections, "trend"
  end

  test "severity rows carry the report's counts" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    rows = CSV.parse(ScorecardDetailCsvReport.new(report).to_csv, headers: true)
    high = rows.find { |r| r["section"] == "severity" && r["label"] == "High" }
    assert_equal report.severity_counts["High"].to_s, high["count"]
  end

  test "filename slugifies the csr name and includes today's date" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    assert_equal "scorecard-jane-doe-#{Date.current.iso8601}.csv",
                 ScorecardDetailCsvReport.new(report).filename
  end

  test "neutralizes formula injection in a breakdown label" do
    report = ScorecardReport.new(csr_name: "Jane Doe")
    report.define_singleton_method(:category_counts) { { "=cmd()" => 1 } }
    rows = CSV.parse(ScorecardDetailCsvReport.new(report).to_csv, headers: true)
    injected = rows.find { |r| r["section"] == "category" }
    assert_equal "'=cmd()", injected["label"]
  end
end
