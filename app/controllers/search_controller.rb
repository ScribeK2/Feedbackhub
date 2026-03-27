class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    results = []

    if @query.present?
      FeedbackSubmission.includes(:feedback_template).search(@query).limit(10).each do |s|
        results << { type: :feedback, record: s }
      end

      Article.search(@query).includes(:author).limit(10).each do |a|
        results << { type: :article, record: a }
      end
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
end
