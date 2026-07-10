class Article < ApplicationRecord
  include SearchIndexable

  belongs_to :author, class_name: "User"
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_rich_text :body

  validates :title, presence: true

  scope :search, ->(q) {
    left_joins(:tags).where(
      "articles.title LIKE :q OR tags.name LIKE :q",
      q: "%#{sanitize_sql_like(q)}%"
    ).distinct
  }

  after_create_commit :broadcast_to_dashboard

  def search_parent
    self
  end

  def search_content
    [ title, body.to_plain_text, *tags.reload.pluck(:name) ]
      .map(&:presence).compact.join("\n")
  end

  private

  def broadcast_to_dashboard
    broadcast_prepend_to "dashboard",
      target: "recent_activity",
      html: ApplicationController.render(Dashboard::ActivityItemComponent.new(item: self, type: :article), layout: false)
  end
end
