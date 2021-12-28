class TaikaiPolicy < ApplicationPolicy
  attr_reader :user, :taikai

  def initialize(user, taikai)
    @user = user
    @taikai = taikai
  end

  def update?
    check
  end

  def destroy?
    check
  end

  private

  def check
    taikai.staffs.joins(:role).where(user: user).where('role.code': StaffRole::ADMIN_CODE).any?
  end
end