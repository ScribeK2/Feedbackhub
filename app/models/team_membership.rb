class TeamMembership < ApplicationRecord
  belongs_to :manager, class_name: "User"

  before_validation :canonicalize_csr_name

  validates :csr_name, presence: true,
    uniqueness: { scope: :manager_id, case_sensitive: false }
  validate :csr_name_must_be_registered

  scope :for_csr, ->(name) { where("LOWER(csr_name) = ?", name.to_s.downcase) }

  private

  def canonicalize_csr_name
    csr = Csr.lookup(csr_name)
    self.csr_name = csr.name if csr
  end

  def csr_name_must_be_registered
    return if csr_name.blank?

    errors.add(:csr_name, "is not a registered CSR") unless Csr.lookup(csr_name)
  end
end
