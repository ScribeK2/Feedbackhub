class User < ApplicationRecord
  has_secure_password

  has_many :articles, foreign_key: :author_id, dependent: :destroy
  has_many :updates, foreign_key: :author_id, dependent: :destroy
  has_many :team_memberships, foreign_key: :manager_id, dependent: :destroy
  has_many :comments, foreign_key: :author_id, dependent: :destroy
  has_many :status_changes, foreign_key: :actor_id, dependent: :destroy
  has_many :feedback_subscriptions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin user manager] }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def admin?
    role == "admin"
  end

  def manager?
    role == "manager"
  end

  def team_csr_names
    team_memberships.pluck(:csr_name)
  end

  def team_scoped?
    manager? && team_memberships.exists?
  end

  def stream_for(base)
    team_scoped? ? "#{base}:#{id}" : base
  end

  def self.managers_for(csr_name)
    return none if csr_name.blank?

    where(role: "manager").where(id: TeamMembership.for_csr(csr_name).select(:manager_id))
  end
end
