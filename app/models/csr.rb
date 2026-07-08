class Csr < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }

  before_validation :strip_name
  after_update :rewrite_references_after_rename, if: :saved_change_to_name?

  # Canonical registry lookup: case-insensitive, whitespace-tolerant.
  # Named `lookup` to avoid shadowing Active Record's exact-match
  # find_by_name dynamic finder.
  def self.lookup(name)
    return nil if name.blank?

    where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end

  def submission_count
    FeedbackSubmission.for_csrs(name).count
  end

  def membership_count
    TeamMembership.for_csr(name).count
  end

  def referenced?
    submission_count.positive? || membership_count.positive?
  end

  # Repoints every reference from this CSR to target, then removes this
  # registry row. Team memberships that would collide with an existing
  # membership of the target are dropped instead of repointed.
  def merge_into!(target)
    raise ArgumentError, "cannot merge a CSR into itself" if target == self

    transaction do
      source_name = name
      destroy!
      target.rewrite_references(source_name)
    end
  end

  protected

  # Rewrites csr_name columns and the data["csr"] JSON key from old_name to
  # this CSR's name. Saving each submission re-runs extract_grouping_fields,
  # keeping column and JSON in sync through the one existing code path.
  def rewrite_references(old_name)
    FeedbackSubmission.for_csrs(old_name).find_each do |submission|
      submission.data["csr"] = name
      submission.save!
    end

    TeamMembership.for_csr(old_name).find_each do |membership|
      if TeamMembership.where(manager_id: membership.manager_id).for_csr(name).where.not(id: membership.id).exists?
        membership.destroy!
      else
        membership.update!(csr_name: name)
      end
    end
  end

  private

  def strip_name
    self.name = name.to_s.strip if name
  end

  def rewrite_references_after_rename
    rewrite_references(saved_change_to_name.first)
  end
end
