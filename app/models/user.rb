class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable
  audited

  validates :firstname, :lastname, presence: true

  self.non_audited_columns = [:encrypted_password]

  scope :confirmed, -> { where.not("confirmed_at IS NULL") }
  scope :containing, ->(query) { confirmed.where <<~SQL, "%#{query}%", "%#{query}%", "%#{query}%" }
    email ILIKE ? OR firstname ILIKE ? OR lastname ILIKE ?
  SQL

  def display_name
    "#{firstname} #{lastname}"
  end
end
