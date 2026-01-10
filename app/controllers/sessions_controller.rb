class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  
  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    
    if user&.authenticate(params[:password])
      if user.confirmed_at.present?
        start_new_session_for(user)
        redirect_to after_authentication_url, notice: t("sessions.signed_in")
      else
        redirect_to new_session_path, alert: t("devise.failure.unconfirmed")
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
