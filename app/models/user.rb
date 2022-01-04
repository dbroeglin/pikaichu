class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable
  audited

  self.non_audited_columns = [:encrypted_password]

  scope :containing, -> (query) { where <<~SQL, "%#{query}%" }
    email ILIKE ?
  SQL

  def display_name
    "#{firstname} #{lastname}"
  end
end
