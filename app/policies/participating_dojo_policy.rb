class ParticipatingDojoPolicy < ApplicationPolicy
  attr_reader :user, :participating_dojo

  def initialize(user, participating_dojo)
    @user = user
    @participating_dojo = participating_dojo
  end

  def update?
    # TODO: optimize?
    @participating_dojo.staffs.joins(:role).where(user: @user, 'role.code': :dojo_admin).any? ||
      @participating_dojo.taikai.staffs.joins(:role).where(user: @user, 'role.code': :taikai_admin).any?
  end

  class Scope < Scope
    def resolve
    end
  end
end