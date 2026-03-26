class FeedbackTemplate < ApplicationRecord
  has_many :feedback_submissions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :field_schema, presence: true
end
