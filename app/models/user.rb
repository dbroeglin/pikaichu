class User < ApplicationRecord
  audited

  # Rails 8 authentication
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Normalize email_address before save
  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :firstname, :lastname, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  self.non_audited_columns = [ :password_digest ]

  scope :confirmed, -> { where.not("confirmed_at IS NULL") }
  scope :containing, ->(query) { confirmed.where <<~SQL, "%#{query}%", "%#{query}%", "%#{query}%" }
    email_address ILIKE ? OR firstname ILIKE ? OR lastname ILIKE ?
  SQL

  def display_name
    "#{firstname} #{lastname}"
  end

  # Alias for backward compatibility with fixtures and tests
  alias_attribute :email, :email_address

  # Generate signed password reset token (Rails 8 style)
  def generate_password_reset_token
    signed_id expires_in: 15.minutes, purpose: :password_reset
  end

  # Find user by password reset token
  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
  end
end
