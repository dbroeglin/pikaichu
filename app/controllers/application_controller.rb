class ApplicationController < ActionController::Base
  include Pundit

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:firstname, :lastname, :email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:firstname, :lastname, :email])
  end

  def user_not_authorized(exception)
    # Here I've got the exception with :policy, :record and :query,
    # also I can access :current_user so I could go for a condition,
    # but that would include duplicated code from  ItemPolicy#show?.
    flash[:alert] = "You are not permitted to execute this action."
    redirect_to root_path
  end
end
