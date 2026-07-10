# frozen_string_literal: true

require "test_helper"

class SearchEntryTest < ActiveSupport::TestCase
  def build_entry(content:, parent_type: "FeedbackSubmission", parent_id: 1, unit_type: "Comment", unit_id: nil)
    SearchEntry.create!(
      parent_type: parent_type, parent_id: parent_id,
      unit_type: unit_type, unit_id: unit_id || (SearchEntry.maximum(:unit_id).to_i + 1),
      content: content
    )
  end

  # --- sanitizer ---

  test "sanitize_fts_query quotes terms and prefix-matches the last" do
    assert_equal '"refund" "proc"*', SearchEntry.sanitize_fts_query("refund proc")
  end

  test "sanitize_fts_query neutralizes FTS5 operators and quotes" do
    assert_equal '"a" "AND" "(b"*', SearchEntry.sanitize_fts_query('"a AND (b')
    assert_equal '"c"*', SearchEntry.sanitize_fts_query('c*')
  end

  test "sanitize_fts_query returns nil for empty or unusable input" do
    assert_nil SearchEntry.sanitize_fts_query("")
    assert_nil SearchEntry.sanitize_fts_query("   ")
    assert_nil SearchEntry.sanitize_fts_query('"" ** ')
    assert_nil SearchEntry.sanitize_fts_query(nil)
  end

  # --- matching ---

  test "matching finds entries by content word" do
    entry = build_entry(content: "the refund was never processed")
    assert_includes SearchEntry.matching("refund", parent_type: "FeedbackSubmission"), entry
  end

  test "matching stems via porter tokenizer" do
    entry = build_entry(content: "customer complained about processing delays")
    assert_includes SearchEntry.matching("processed", parent_type: "FeedbackSubmission"), entry
  end

  test "matching filters by parent_type" do
    build_entry(content: "shared keyword", parent_type: "Article", unit_type: "Article")
    assert_empty SearchEntry.matching("shared", parent_type: "FeedbackSubmission")
  end

  test "matching ANDs multiple terms" do
    yes = build_entry(content: "refund processed late")
    build_entry(content: "refund only")
    results = SearchEntry.matching("refund processed", parent_type: "FeedbackSubmission")
    assert_includes results, yes
    assert_equal 1, results.count
  end

  test "matching returns none for garbage query without raising" do
    assert_empty SearchEntry.matching('""', parent_type: "FeedbackSubmission")
  end

  test "matching is composable" do
    e1 = build_entry(content: "composable target", parent_id: 42)
    build_entry(content: "composable target", parent_id: 43)
    assert_equal [ e1.id ], SearchEntry.matching("composable", parent_type: "FeedbackSubmission").where(parent_id: 42).pluck(:id)
  end

  # --- matching_ranked ---

  test "matching_ranked orders best match first and provides sentinel-marked snippets" do
    build_entry(content: "refund mentioned once amid many many other unrelated words here")
    best = build_entry(content: "refund refund refund")
    results = SearchEntry.matching_ranked("refund", parent_type: "FeedbackSubmission").to_a
    assert_equal best.id, results.first.id
    assert_includes results.first.snippet, "#{SearchEntry::SNIPPET_START}refund#{SearchEntry::SNIPPET_END}"
  end

  # --- rebuild! ---

  test "rebuild! indexes fixture rows that bypassed callbacks" do
    assert_nil SearchEntry.find_by(unit_type: "FeedbackSubmission", unit_id: feedback_submissions(:high_priority).id)
    SearchEntry.rebuild!
    entry = SearchEntry.find_by(unit_type: "FeedbackSubmission", unit_id: feedback_submissions(:high_priority).id)
    assert_includes entry.content, "TK-001"
  end

  test "rebuild! converges from drifted state and is idempotent" do
    SearchEntry.rebuild!
    drifted = SearchEntry.find_by(unit_type: "FeedbackSubmission", unit_id: feedback_submissions(:high_priority).id)
    drifted.update!(content: "stale garbage")
    SearchEntry.create!(parent_type: "FeedbackSubmission", parent_id: 0, unit_type: "Comment", unit_id: 999_999, content: "orphan")

    SearchEntry.rebuild!
    first_pass = SearchEntry.order(:unit_type, :unit_id).pluck(:unit_type, :unit_id, :content)
    assert_nil SearchEntry.find_by(unit_id: 999_999)
    assert_includes SearchEntry.find_by(unit_type: "FeedbackSubmission", unit_id: feedback_submissions(:high_priority).id).content, "TK-001"

    SearchEntry.rebuild!
    assert_equal first_pass, SearchEntry.order(:unit_type, :unit_id).pluck(:unit_type, :unit_id, :content)
  end
end
