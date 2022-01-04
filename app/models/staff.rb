class Staff < ApplicationRecord
  audited

  belongs_to :role, class_name: "StaffRole"
  belongs_to :taikai
  belongs_to :participating_dojo, optional: true
  belongs_to :user, optional: true

  validate do
    if (role.taikai_admin? || role.dojo_admin?) && user.nil?
      errors.add(:user, "is mandatory for an administrator staff")
    end
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

  def last_taikai_admin?
    role.taikai_admin? && taikai.staffs.where(role: self.role).count == 1
  end
end