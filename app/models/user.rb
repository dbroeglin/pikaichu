class User < ApplicationRecord
  audited
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  # Rails 8 authentication
  has_secure_password
  has_many :sessions, dependent: :destroy

  # Rails 8: Normalize fields before save
  normalizes :email_address, with: ->(email) { email.strip.downcase }
  normalizes :firstname, :lastname, with: ->(name) { name.strip.titlecase }

  validates :firstname, :lastname, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true

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
    generate_token_for(:password_reset)
  end

  # Find user by password reset token
  def self.find_by_password_reset_token!(token)
    find_by_token_for!(:password_reset, token)
  end
end
