class SearchController < ApplicationController
  RESULT_LIMIT = 10
  SOURCE_LABELS = { "Comment" => "in comment", "StatusChange" => "in status note" }.freeze

  def index
    @query = params[:q].to_s.strip
    results = []

    if @query.present?
      results.concat ranked_results(:feedback, "FeedbackSubmission",
        team_scoped(FeedbackSubmission.includes(:feedback_template)))
      results.concat ranked_results(:article, "Article", Article.includes(:author))
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "search_results",
          Search::ResultsComponent.new(results: results, query: @query)
        )
      end
      format.html do
        render Search::ResultsComponent.new(results: results, query: @query)
      end
    end
  end

  private

  # Best-ranked entry per parent, resolved through the (possibly
  # team-scoped) record relation so scoping is enforced at fetch time.
  def ranked_results(type, parent_type, records_relation)
    best_entries = {}
    SearchEntry.matching_ranked(@query, parent_type: parent_type)
      .limit(RESULT_LIMIT * 5)
      .each { |entry| best_entries[entry.parent_id] ||= entry }

    records = records_relation.where(id: best_entries.keys).index_by(&:id)
    best_entries.keys.filter_map do |parent_id|
      record = records[parent_id] or next
      entry = best_entries[parent_id]
      {
        type: type, record: record,
        snippet: entry.snippet, source: SOURCE_LABELS[entry.unit_type]
      }
    end.first(RESULT_LIMIT)
  end
end
