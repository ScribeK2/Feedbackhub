class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, presence: true, uniqueness: true

  before_validation :normalize_name

  scope :matching, ->(q) { where("name LIKE ?", "%#{sanitize_sql_like(q)}%") }

  # Repoints article references to target — dropping joins whose article
  # already carries the target tag — then removes this tag.
  def merge_into!(target)
    raise ArgumentError, "cannot merge a tag into itself" if target == self

    transaction do
      article_tags.to_a.each do |article_tag|
        if ArticleTag.exists?(article_id: article_tag.article_id, tag_id: target.id)
          article_tag.destroy!
        else
          article_tag.update!(tag_id: target.id)
        end
      end
      reload
      destroy!
    end
  end

  private

  def normalize_name
    self.name = name.to_s.strip.downcase if name
  end
end
