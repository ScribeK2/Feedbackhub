# frozen_string_literal: true

require "test_helper"

class SearchIndexableTest < ActiveSupport::TestCase
  # NOTE: after_*_commit callbacks DO fire inside this suite's transactional
  # tests (Rails 7.1+ behavior — comment_test.rb already relies on it for
  # subscribe_author), so no use_transactional_tests override is needed.

  def create_submission(details: nil)
    FeedbackSubmission.create!(
      feedback_template: feedback_templates(:csr_feedback),
      feedback_details: details,
      data: {
        "ticket_number" => "TK-FTS", "csr" => "Jane Doe", "feedback_type" => "Knowledge Gap",
        "impact" => "Resolution Time", "priority" => "High", "submitted_by" => "Indexer"
      }
    )
  end

  def entry_for(record)
    SearchEntry.find_by(unit_type: record.class.name, unit_id: record.id)
  end

  test "submission create indexes columns, data values, and details plain text" do
    submission = create_submission(details: "<div>Lexxy <b>rich</b> narrative</div>")
    entry = entry_for(submission)
    assert_equal "FeedbackSubmission", entry.parent_type
    assert_equal submission.id, entry.parent_id
    assert_includes entry.content, "TK-FTS"
    assert_includes entry.content, "Knowledge Gap"
    assert_includes entry.content, "Lexxy rich narrative"
    assert_not_includes entry.content, "<div>" # plain text, never HTML
  end

  test "submission update resyncs its entry" do
    submission = create_submission
    submission.update!(data: submission.data.merge("ticket_number" => "TK-CHANGED"))
    assert_includes entry_for(submission).content, "TK-CHANGED"
  end

  test "comment create/update/destroy tracks a parent-pointing entry" do
    submission = create_submission
    comment = Comment.create!(feedback_submission: submission, author: users(:regular), body: "refund never arrived")
    entry = entry_for(comment)
    assert_equal [ "FeedbackSubmission", submission.id ], [ entry.parent_type, entry.parent_id ]
    assert_includes entry.content, "refund"

    comment.update!(body: "compensation never arrived")
    assert_includes entry_for(comment).content, "compensation"

    comment.destroy
    assert_nil entry_for(comment)
  end

  test "status change with note gets an entry; without note gets none" do
    submission = create_submission
    submission.transition_to("reviewed", actor: users(:manager))
    reviewed = submission.status_changes.chronological.last
    assert_nil entry_for(reviewed)

    submission.transition_to("dismissed", actor: users(:manager), note: "duplicate of TK-9")
    dismissed = submission.status_changes.chronological.last
    assert_includes entry_for(dismissed).content, "duplicate"
  end

  test "destroying a submission removes its entry and its children's entries" do
    submission = create_submission
    comment = Comment.create!(feedback_submission: submission, author: users(:regular), body: "cascade me")
    submission.destroy
    assert_nil entry_for(submission)
    assert_nil entry_for(comment)
  end

  test "article indexes title, body plain text, and tag names — including tags assigned after save" do
    article = Article.create!(title: "Refund runbook", author: users(:admin), body: "<p>Escalate to <i>billing</i></p>")
    entry = entry_for(article)
    assert_includes entry.content, "Refund runbook"
    assert_includes entry.content, "Escalate to billing"

    tag = Tag.create!(name: "billing-ops")
    ArticleTag.create!(article: article, tag: tag) # controller assigns tags AFTER article save
    assert_includes entry_for(article).content, "billing-ops"
  end

  test "tag rename resyncs its articles" do
    article = Article.create!(title: "Tagged piece", author: users(:admin))
    tag = Tag.create!(name: "old-name")
    ArticleTag.create!(article: article, tag: tag)

    tag.update!(name: "new-name")
    content = entry_for(article).content
    assert_includes content, "new-name"
    assert_not_includes content, "old-name"
  end

  test "destroying an article with tags removes its entry (no stale row)" do
    article = Article.create!(title: "Doomed", author: users(:admin))
    ArticleTag.create!(article: article, tag: Tag.create!(name: "doomed-tag"))
    assert entry_for(article)
    article.destroy
    assert_nil entry_for(article)
  end

  test "tag merge resyncs the affected articles" do
    article = Article.create!(title: "Merge piece", author: users(:admin))
    source = Tag.create!(name: "src-tag")
    target = Tag.create!(name: "dst-tag")
    ArticleTag.create!(article: article, tag: source)

    source.merge_into!(target)
    content = entry_for(article).content
    assert_includes content, "dst-tag"
    assert_not_includes content, "src-tag"
  end
end
