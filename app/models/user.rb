class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable
  audited

  # Rails 8 authentication (running in parallel with Devise)
  has_secure_password validations: false  # Disable validations to avoid conflicts with Devise
  has_many :sessions, dependent: :destroy

  # Normalize email_address before save (Rails 8 convention)
  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :firstname, :lastname, presence: true
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, presence: true
  
  # Rails 8 email validation (only if email_address is present)
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :email_address?

  self.non_audited_columns = [ :encrypted_password, :password_digest ]

  scope :confirmed, -> { where.not("confirmed_at IS NULL") }
  scope :containing, ->(query) { confirmed.where <<~SQL, "%#{query}%", "%#{query}%", "%#{query}%" }
    email ILIKE ? OR firstname ILIKE ? OR lastname ILIKE ?
  SQL

  def display_name
    "#{firstname} #{lastname}"
  end

  # Generate signed password reset token (Rails 8 style)
  def generate_password_reset_token
    signed_id expires_in: 15.minutes, purpose: :password_reset
  end

  # Find user by password reset token
  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
  end
end
