require "test_helper"

class Rails8AuthenticationTest < ActionDispatch::IntegrationTest
  include Rails8AuthTestHelper

  setup do
    @user = users(:jean_bon)
    @password = "password123"
    # Use test helper to set up Rails 8 authentication
    setup_rails8_auth_for(@user, @password)
    @user.update_column(:confirmed_at, Time.current) # Ensure user is confirmed
  end

  test "can access login page" do
    get new_session_path
    assert_response :success
    assert_select "h1.title", text: I18n.t("sessions.new.title")
    assert_select "input[type=email][name=email_address]"
    assert_select "input[type=password][name=password]"
  end

  test "can sign in with valid credentials" do
    post session_path, params: {
      email_address: @user.email_address,
      password: @password
    }

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_equal I18n.t("sessions.signed_in"), flash[:notice]
  end

  test "cannot sign in with invalid password" do
    post session_path, params: {
      email_address: @user.email_address,
      password: "wrong_password"
    }

    assert_response :unprocessable_entity
    assert_select ".notification.is-danger, div[role=alert]",
                  text: I18n.t("sessions.invalid_credentials")
  end

  test "cannot sign in with non-existent email" do
    post session_path, params: {
      email_address: "nonexistent@example.com",
      password: @password
    }

    assert_response :unprocessable_entity
  end

  test "cannot sign in if not confirmed" do
    @user.update_column(:confirmed_at, nil)

    post session_path, params: {
      email_address: @user.email_address,
      password: @password
    }

    assert_response :redirect
    assert_equal I18n.t("authentication.unconfirmed"), flash[:alert]
  end

  test "can sign out" do
    # Sign in first
    post session_path, params: {
      email_address: @user.email_address,
      password: @password
    }
    assert_response :redirect

    # Sign out
    delete session_path
    assert_response :redirect
    follow_redirect!
    assert_equal I18n.t("sessions.signed_out"), flash[:notice]
  end

  test "password reset flow" do
    # Request password reset
    get new_password_path
    assert_response :success
    assert_select "h1.title", text: I18n.t("passwords.new.title")

    # Submit reset request
    assert_emails 1 do
      post passwords_path, params: {
        email_address: @user.email_address
      }
    end

    assert_response :redirect
    follow_redirect!
    assert_equal I18n.t("passwords.reset_email_sent"), flash[:notice]
  end

  test "can reset password with valid token" do
    token = @user.generate_password_reset_token

    # Visit reset page
    get edit_password_path(token)
    assert_response :success
    assert_select "h1.title", text: I18n.t("passwords.edit.title")

    # Submit new password
    new_password = "newpassword123"
    patch password_path(token), params: {
      user: {
        password: new_password,
        password_confirmation: new_password
      }
    }

    assert_response :redirect
    follow_redirect!
    assert_equal I18n.t("passwords.password_updated"), flash[:notice]

    # Verify can sign in with new password
    @user.reload
    assert @user.authenticate(new_password)
  end

  test "cannot reset password with invalid token" do
    get edit_password_path("invalid_token")
    assert_response :redirect
    assert_equal I18n.t("passwords.invalid_token"), flash[:alert]
  end

  test "creates session record on sign in" do
    assert_difference "Session.count", 1 do
      post session_path, params: {
        email_address: @user.email_address,
        password: @password
      }
    end

    session = Session.last
    assert_equal @user.id, session.user_id
    assert_equal "127.0.0.1", session.ip_address
  end

  test "destroys session record on sign out" do
    # Sign in
    post session_path, params: {
      email_address: @user.email_address,
      password: @password
    }

    session_count = Session.count

    # Sign out
    assert_difference "Session.count", -1 do
      delete session_path
    end
  end
end
