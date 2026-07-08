class TeamMembership < ApplicationRecord
  belongs_to :manager, class_name: "User"

  validates :csr_name, presence: true,
    uniqueness: { scope: :manager_id, case_sensitive: false }

  scope :for_csr, ->(name) { where("LOWER(csr_name) = ?", name.to_s.downcase) }
end
