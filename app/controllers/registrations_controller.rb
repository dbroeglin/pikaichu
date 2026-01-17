class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  # Rails 8: Rate limit registration attempts to prevent abuse
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> {
    redirect_to new_registration_path, alert: I18n.t("registrations.rate_limit_exceeded")
  }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.confirmed_at = Time.current  # Auto-confirm for now, can add email confirmation later

    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: t("registrations.account_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def registration_params
      params.require(:user).permit(:firstname, :lastname, :email_address, :password, :password_confirmation, :locale)
    end
end
