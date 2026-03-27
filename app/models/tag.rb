class Tag < ApplicationRecord
  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  validates :name, presence: true, uniqueness: true

  scope :matching, ->(q) { where("name LIKE ?", "%#{sanitize_sql_like(q)}%") }
end
