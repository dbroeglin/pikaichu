class ParticipatingDojoPolicy < ApplicationPolicy
  attr_reader :user, :participating_dojo

  def initialize(user, participating_dojo)
    super
    @user = user
    @participating_dojo = participating_dojo
  end

  def edit?
    update?
  end

  def update?
    # TODO: optimize?
    user.admin? ||
      @participating_dojo.staffs.joins(:role).where(user: @user, 'role.code': :dojo_admin).any? ||
      @participating_dojo.taikai.staffs.joins(:role).where(user: @user, 'role.code': :taikai_admin).any?
  end

  def import?
    update?
  end

  def destroy?
    update?
  end

  class Scope < Scope
    def resolve; end
  end
end