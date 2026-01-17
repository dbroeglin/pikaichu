require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new registration page" do
    get new_registration_url
    assert_response :success
    assert_select "h1", I18n.t("registrations.new.title")
  end

  test "should create user with valid params" do
    assert_difference("User.count", 1) do
      post registrations_url, params: {
        user: {
          firstname: "John",
          lastname: "Doe",
          email_address: "john.doe@example.com",
          password: "password123",
          password_confirmation: "password123",
          locale: "en"
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_equal I18n.t("registrations.account_created"), flash[:notice]

    # User should be logged in
    assert session[:session_id].present?

    # User should be confirmed
    user = User.find_by(email_address: "john.doe@example.com")
    assert user.confirmed_at.present?
  end

  test "should not create user with invalid email" do
    assert_no_difference("User.count") do
      post registrations_url, params: {
        user: {
          firstname: "John",
          lastname: "Doe",
          email_address: "invalid-email",
          password: "password123",
          password_confirmation: "password123",
          locale: "en"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".notification.is-danger"
  end

  test "should not create user with short password" do
    assert_no_difference("User.count") do
      post registrations_url, params: {
        user: {
          firstname: "John",
          lastname: "Doe",
          email_address: "john.doe@example.com",
          password: "short",
          password_confirmation: "short",
          locale: "en"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".notification.is-danger"
  end

  test "should not create user with mismatched password confirmation" do
    assert_no_difference("User.count") do
      post registrations_url, params: {
        user: {
          firstname: "John",
          lastname: "Doe",
          email_address: "john.doe@example.com",
          password: "password123",
          password_confirmation: "different123",
          locale: "en"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".notification.is-danger"
  end

  test "should not create user with duplicate email" do
    # Create first user
    User.create!(
      firstname: "Jane",
      lastname: "Smith",
      email_address: "john.doe@example.com",
      password: "password123",
      locale: "en",
      confirmed_at: Time.current
    )

    assert_no_difference("User.count") do
      post registrations_url, params: {
        user: {
          firstname: "John",
          lastname: "Doe",
          email_address: "john.doe@example.com",
          password: "password123",
          password_confirmation: "password123",
          locale: "en"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should normalize email to lowercase" do
    post registrations_url, params: {
      user: {
        firstname: "John",
        lastname: "Doe",
        email_address: "John.Doe@Example.COM",
        password: "password123",
        password_confirmation: "password123",
        locale: "en"
      }
    }

    user = User.find_by(email_address: "john.doe@example.com")
    assert user.present?
  end

  test "should normalize names to titlecase" do
    post registrations_url, params: {
      user: {
        firstname: "john",
        lastname: "DOE",
        email_address: "john.doe@example.com",
        password: "password123",
        password_confirmation: "password123",
        locale: "en"
      }
    }

    user = User.find_by(email_address: "john.doe@example.com")
    assert_equal "John", user.firstname
    assert_equal "Doe", user.lastname
  end

  test "should require all mandatory fields" do
    assert_no_difference("User.count") do
      post registrations_url, params: {
        user: {
          firstname: "",
          lastname: "",
          email_address: "",
          password: "",
          locale: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should enforce rate limiting" do
    # Stub rate limiter to trigger limit
    # This would require additional setup in test environment
    # Skipping for now as it requires request store setup
    skip "Rate limiting requires request store setup in tests"
  end
end
