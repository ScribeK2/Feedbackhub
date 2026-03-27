class ArticlesController < ApplicationController
  before_action :require_admin, only: :destroy

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

  def destroy
    @article = Article.find(params[:id])
    @article.destroy
    redirect_to articles_path, notice: "Article deleted."
  end

  private

  def article_params
    params.require(:article).permit(:title, :body)
  end

  def assign_tags(article, tag_names_string)
    return if tag_names_string.blank?

    tag_names = tag_names_string.split(",").map(&:strip).reject(&:blank?).uniq
    tags = tag_names.map { |name| Tag.find_or_create_by!(name: name.downcase) }
    article.tags = tags
  end
end
