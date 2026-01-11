# Helper methods for Rails 8 authentication testing
module Rails8AuthTestHelper
  # Set up a user with Rails 8 authentication credentials
  # This ensures the user has both email_address and password_digest set
  def setup_rails8_auth_for(user, password = "password")
    user = users(user) if user.is_a?(Symbol)
    
    # Set email_address if not already set
    user.update_column(:email_address, user.email.downcase) unless user.email_address.present?
    
    # Set password using has_secure_password
    user.password = password
    user.password_confirmation = password
    user.save!(validate: false)
    
    user
  end

  # Create a session for a user (simulates login)
  def create_session_for(user)
    user = users(user) if user.is_a?(Symbol)
    session = user.sessions.create!(
      ip_address: "127.0.0.1",
      user_agent: "Test Suite"
    )
    cookies.signed[:session_id] = session.id
    session
  end

  # Authenticate a user using Rails 8 authentication
  # Returns true if authentication succeeds
  def authenticate_rails8_user(email_address, password)
    user = User.find_by(email_address: email_address)
    user&.authenticate(password)
  end

  # Sign in via Rails 8 authentication controllers
  def rails8_sign_in(email_address, password)
    post session_path, params: {
      email_address: email_address,
      password: password
    }
  end

  # Sign out via Rails 8 authentication
  def rails8_sign_out
    delete session_path
  end
end

# Include in integration tests
module ActionDispatch
  class IntegrationTest
    include Rails8AuthTestHelper
  end
end
