class Staff < ApplicationRecord
  belongs_to :role, class_name: "StaffRole"
  belongs_to :taikai
  belongs_to :user, optional: true

  def display_name
    "#{firstname} #{lastname}"
  end
end