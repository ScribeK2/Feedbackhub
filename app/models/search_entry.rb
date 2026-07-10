# frozen_string_literal: true

# One row per searchable unit of content (a submission's own fields, a
# comment, a status-change note, an article), pointing at the parent record
# a search hit resolves to. The search_entries_fts virtual table shadows
# this table via SQL triggers; `content` is always plain text.
class SearchEntry < ApplicationRecord
  SNIPPET_START = ""
  SNIPPET_END = ""

  UNIT_MODELS = -> { [ FeedbackSubmission, Comment, StatusChange, Article ] }

  validates :parent_type, :parent_id, :unit_type, :unit_id, :content, presence: true

  # Truncate and reindex the whole corpus (the FTS shadow follows via
  # triggers). Drift remedy and backfill entry point; safe to re-run.
  def self.rebuild!
    delete_all
    UNIT_MODELS.call.each { |model| model.find_each(&:sync_search_entry) }
  end

  scope :matching, ->(q, parent_type:) {
    fts = sanitize_fts_query(q)
    next none unless fts
    where(parent_type: parent_type)
      .where("search_entries.id IN (SELECT rowid FROM search_entries_fts WHERE search_entries_fts MATCH ?)", fts)
  }

  scope :matching_ranked, ->(q, parent_type:) {
    fts = sanitize_fts_query(q)
    next none unless fts
    where(parent_type: parent_type)
      .joins("JOIN search_entries_fts ON search_entries_fts.rowid = search_entries.id")
      .where("search_entries_fts MATCH ?", fts)
      .select(sanitize_sql_array([
        "search_entries.*, bm25(search_entries_fts) AS search_rank, " \
        "snippet(search_entries_fts, 0, ?, ?, '…', 12) AS snippet",
        SNIPPET_START, SNIPPET_END
      ]))
      .order("search_rank")
  }

  # FTS5 MATCH has its own query syntax; raw user input can raise. Quote
  # every whitespace-separated term (stripping quote/star characters),
  # AND them implicitly, and prefix-match the final term so live typing
  # matches partial words. Returns nil when nothing searchable remains.
  def self.sanitize_fts_query(input)
    terms = input.to_s.split.map { |t| t.delete('"*') }.reject(&:empty?)
    return nil if terms.empty?

    quoted = terms.map { |t| %("#{t}") }
    quoted[-1] = "#{quoted.last}*"
    quoted.join(" ")
  end
end
