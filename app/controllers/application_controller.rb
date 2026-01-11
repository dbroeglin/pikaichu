class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Authentication

  # Rails 8: Only allow modern browsers
  allow_browser versions: :modern

  # Rails 8: Refresh importmap cache when dependencies change
  stale_when_importmap_changes

  before_action :require_authentication
  around_action :switch_locale

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def user_not_authorized(_)
    flash[:alert] = I18n.t("pundit.not_authorized", default: "You are not authorized to perform this action.")
    redirect_to root_path, status: :see_other
  end

  def switch_locale(&)
    locale = params[:locale] || current_user&.locale || I18n.default_locale

    I18n.with_locale(locale, &)
  end
end
