class ArticlesController < ApplicationController
  before_action :require_admin, only: :destroy
  before_action :set_article, only: [ :edit, :update ]
  before_action :require_author_or_admin, only: [ :edit, :update ]

  def index
    @articles = Article.includes(:author, :tags).order(created_at: :desc)
    @articles = @articles.joins(:tags).where(tags: { name: params[:tag] }) if params[:tag].present?

    render Articles::IndexComponent.new(articles: @articles)
  end

  def show
    @article = Article.find(params[:id])
    render Articles::ShowComponent.new(article: @article)
  end

  def new
    @article = Article.new
    render Articles::FormComponent.new(article: @article)
  end

  def create
    @article = current_user.articles.new(article_params)

    assign_tags(@article, params[:tag_names])

    if @article.save
      redirect_to article_path(@article), notice: "Article created successfully!"
    else
      render Articles::FormComponent.new(article: @article), status: :unprocessable_entity
    end
  end

  def edit
    render Articles::FormComponent.new(article: @article)
  end

  def update
    Article.transaction do
      @article.update!(article_params)
      assign_tags(@article, params[:tag_names])
    end

    redirect_to article_path(@article), notice: "Article updated successfully!"
  rescue ActiveRecord::RecordInvalid => e
    # An invalid article populates its own errors; anything else came from
    # tag assignment and would otherwise re-render a form with no message.
    @article.errors.add(:base, "Could not update tags: #{e.message}") if @article.errors.empty?
    render Articles::FormComponent.new(article: @article), status: :unprocessable_entity
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy
    redirect_to articles_path, notice: "Article deleted."
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def require_author_or_admin
    unless current_user&.admin? || @article.author == current_user
      redirect_to article_path(@article), alert: "You can only edit your own articles."
    end
  end

  def article_params
    params.require(:article).permit(:title, :body)
  end

  def assign_tags(article, tag_names_string)
    return if tag_names_string.nil?

    tag_names = tag_names_string.split(",").map(&:strip).reject(&:blank?).uniq
    tags = tag_names.map { |name| find_or_create_tag(name.downcase) }
    article.tags = tags
  end

  # A concurrent request can insert the same tag between our find and our
  # insert, so the unique index — not the uniqueness validation — is what
  # settles the race. The loser reads the winner's row.
  def find_or_create_tag(name)
    Tag.find_or_create_by!(name: name)
  rescue ActiveRecord::RecordNotUnique
    Tag.find_by!(name: name)
  end
end
