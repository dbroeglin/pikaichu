class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  
  # Rails 8: Rate limit login attempts to prevent brute force attacks
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_path, alert: I18n.t("sessions.rate_limit_exceeded")
  }

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      if user.confirmed_at.present?
        start_new_session_for(user)
        redirect_to after_authentication_url, notice: t("sessions.signed_in")
      else
        redirect_to new_session_path, alert: t("authentication.unconfirmed")
      end
    else
      flash.now[:alert] = t("sessions.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: t("sessions.signed_out")
  end
end
