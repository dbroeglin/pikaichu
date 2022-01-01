class Staff < ApplicationRecord
  belongs_to :role, class_name: "StaffRole"
  belongs_to :taikai
  belongs_to :participating_dojo, optional: true
  belongs_to :user, optional: true

  validate do
    errors.add(:user, "is mandatory for an admin staff") if role.code == 'admin' && user.nil?
  end

  before_validation do
    if self.user
      self.firstname = self.user.firstname
      self.lastname = self.user.lastname
    end
  end

  def display_name
    "#{firstname} #{lastname}"
  end

  def last_admin?
    role.code == 'admin' && taikai.staffs.where(role: self.role).count == 1
  end
end