class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Authentication
  
  before_action :require_authentication
  around_action :switch_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def user_not_authorized(_)
    flash[:alert] = I18n.t("pundit.not_authorized", default: "You are not authorized to perform this action.")
    redirect_to root_path, method: :get
  end

  def switch_locale(&)
    locale = params[:locale] || current_user&.locale || I18n.default_locale

    I18n.with_locale(locale, &)
  end
end
