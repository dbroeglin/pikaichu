class ParticipatingDojoPolicy < ApplicationPolicy
  attr_reader :user, :participating_dojo

  def initialize(user, participating_dojo)
    @user = user
    @taikai = participating_dojo
  end

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      scope.joins()
    end

    private

    attr_reader :user, :scope
  end
end