class Csr < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }

  # Canonical registry lookup: case-insensitive, whitespace-tolerant.
  # Named `lookup` to avoid shadowing Active Record's exact-match
  # find_by_name dynamic finder.
  def self.lookup(name)
    return nil if name.blank?

    where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end
end
