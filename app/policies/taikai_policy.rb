class TaikaiPolicy < ApplicationPolicy
  attr_reader :user, :taikai

  def initialize(user, taikai)
    @user = user
    @taikai = taikai
  end

  def update?
    taikai.staffs.joins(:role).where(user: user).where('role.code': StaffRole::ADMIN_CODE).any?
  end
end