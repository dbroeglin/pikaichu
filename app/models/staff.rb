class Staff < ApplicationRecord
  belongs_to :role, class_name: "StaffRole"
  belongs_to :taikai
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

  before_destroy do
    if self.role.code == 'admin' && taikai.staffs.where(role: self.role).count == 1
      logger.warn("Unable to destroy Staff #{self.id}, he is the last admin for Taikai #{self.taikai.id}")
      throw :abort
    end
  end

  def display_name
    "#{firstname} #{lastname}"
  end
end