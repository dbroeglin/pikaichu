class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  around_action :switch_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:firstname, :lastname, :email, :locale])
    devise_parameter_sanitizer.permit(:account_update, keys: [:firstname, :lastname, :email, :locale])
  end

  def user_not_authorized(_)
    # Here I've got the exception with :policy, :record and :query,
    # also I can access :current_user so I could go for a condition,
    # but that would include duplicated code from  ItemPolicy#show?.
    flash[:alert] = I18n.t('pundit.not_authorized', default: 'You are not authorized to perform this action.')
    redirect_to root_path, method: :get
  end

  def switch_locale(&)
    locale = params[:locale] || current_user&.locale || I18n.default_locale

    I18n.with_locale(locale, &)
  end
end
