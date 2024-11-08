class Staff < ApplicationRecord
  include ValidateChangeBasedOnState
  audited

  belongs_to :role, class_name: "StaffRole"
  belongs_to :taikai
  belongs_to :participating_dojo, optional: true
  belongs_to :user, optional: true

  validates :firstname, :lastname, presence: true
  validates :user,
            presence: {
              if: -> { role.taikai_admin? || role.dojo_admin? || role.marking_referee? }
            }
  validates :participating_dojo_id,
            presence: {
              if: -> { role.dojo_admin? || role.marking_referee? || role.yatori? }
            }

  before_validation do
    if self.user
      self.firstname = self.user.firstname
      self.lastname = self.user.lastname
    end
  end

  validate do |staff|
    if !new_record? &&
       !staff.role.taikai_admin? &&
       taikai.staffs.with_role(:taikai_admin).where("staffs.id <> ?", staff.id).empty?
      errors.add(:base, :at_least_one_admin)
    end
  end

  before_destroy prepend: true do
    if role.taikai_admin? && taikai.staffs.with_role(:taikai_admin).count == 1
      errors.add(:base, :at_least_one_admin)
      throw :abort
    end unless destroyed_by_association
  end

  def display_name
    "#{firstname} #{lastname}"
  end

  def to_ascii
    "#{display_name} - #{role&.code} - #{participating_dojo&.display_name} (#{id})"
  end
end