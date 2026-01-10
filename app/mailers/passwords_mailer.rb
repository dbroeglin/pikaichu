class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @token = user.generate_password_reset_token

    mail to: user.email_address, subject: t("passwords_mailer.reset.subject")
  end
end
