class MigrateUserAuthenticationColumns < ActiveRecord::Migration[8.1]
  def up
    # Copy data from Devise columns to Rails 8 columns
    User.reset_column_information

    User.find_each do |user|
      # Copy email to email_address if email_address is blank
      if user.email_address.blank? && user.email.present?
        user.update_column(:email_address, user.email)
      end

      # Copy encrypted_password to password_digest if password_digest is blank
      if user.password_digest.blank? && user.encrypted_password.present?
        user.update_column(:password_digest, user.encrypted_password)
      end
    end
  end

  def down
    # Copy data back from Rails 8 columns to Devise columns
    User.reset_column_information

    User.find_each do |user|
      if user.email.blank? && user.email_address.present?
        user.update_column(:email, user.email_address)
      end

      if user.encrypted_password.blank? && user.password_digest.present?
        user.update_column(:encrypted_password, user.password_digest)
      end
    end
  end
end
