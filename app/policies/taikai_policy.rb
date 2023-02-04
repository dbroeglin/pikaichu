class TaikaiPolicy < ApplicationPolicy
  attr_reader :user, :taikai

  ADMIN_ROLES = [:taikai_admin, :dojo_admin]
  MARKING_ROLES = ADMIN_ROLES + [:marking_referee, :target_referee]

  def initialize(user, taikai)
    super
    @user = user
    @taikai = taikai
  end

  def admin?
    user.admin? || taikai.has_roles?(user, ADMIN_ROLES)
  end

  def draw?
    update?
  end

  def destroy?
    update?
  end

  def edit?
    update?
  end

  def export?
    taikai.in_state?(:done) && show?
  end

  def import_participants?
    update?
  end

  def leaderboard_show?
    !taikai.in_state?(:new, :registration) && show?
  end

  def tie_break_show?
    taikai.in_state?(:tie_break) && show?
  end

  def marking_show?
    marking_update?
  end

  def marking_update?
    taikai.in_state?(:marking) && (user.admin? || taikai.has_roles?(user, MARKING_ROLES))
  end

  def show?
    true
  end

  def tie_break_update?
    taikai.in_state?(:tie_break) && (user.admin? || taikai.has_roles?(user, MARKING_ROLES)) # TODO: double check if MARKING_ROLES is right
  end

  def transition_to?
    update?
  end

  def update?
    admin?
  end
end