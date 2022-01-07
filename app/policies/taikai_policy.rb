class TaikaiPolicy < ApplicationPolicy
  attr_reader :user, :taikai

  def initialize(user, taikai)
    @user = user
    @taikai = taikai
  end

  def edit?
    taikai.staffs.joins(:role).where(user: user, 'role.code': [:taikai_admin, :dojo_admin]).any?
  end

  def update?
    taikai.taikai_admin?(user)
  end

  def draw?
    update?
  end

  def destroy?
    update?
  end
end