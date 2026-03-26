class FeedbackTemplate < ApplicationRecord
  has_many :feedback_submissions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :field_schema, presence: true
  validate :field_schema_is_array

  private

  def field_schema_is_array
    return if field_schema.blank?
    unless field_schema.is_a?(Array)
      errors.add(:field_schema, "must be a valid JSON array")
    end
  end
end
