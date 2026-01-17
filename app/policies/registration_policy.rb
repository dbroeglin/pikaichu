class RegistrationPolicy < ApplicationPolicy
  # Anyone can view the registration form
  def new?
    true
  end

  # Anyone can create a new account
  def create?
    true
  end
end
