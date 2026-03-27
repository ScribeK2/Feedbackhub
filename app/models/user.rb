class User < ApplicationRecord
  has_secure_password

  has_many :articles, foreign_key: :author_id, dependent: :destroy
  has_many :updates, foreign_key: :author_id, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin user] }

  def admin?
    role == "admin"
  end
end
