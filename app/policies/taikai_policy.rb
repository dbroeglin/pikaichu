class TaikaiPolicy < ApplicationPolicy
  attr_reader :user, :taikai

  def initialize(user, taikai)
    super
    @user = user
    @taikai = taikai
  end

  def edit?
    user.admin? ||
      taikai.staffs.joins(:role).where(user: user, 'role.code': [:taikai_admin, :dojo_admin]).any?
  end

  def update?
    user.admin? ||
      taikai.taikai_admin?(user)
  end

  def draw?
    update?
  end

  def destroy?
    update?
  end
end