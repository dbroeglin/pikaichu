ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "taikais_test_helpers"
require_relative "helpers/rails8_auth_test_helper"

Faker::Config.random = Random.new(42)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module SignInHelper
  # Devise-based sign in (legacy)
  def sign_in_as_devise(user)
    user = users(user)
    throw "Sign-in helper needs a user" if user.nil?

    post user_session_path(user: { email: user.email, password: "password" })

    assert_response :redirect
    follow_redirect!
    assert_response :success

    assert_select "p.title", text: "Taikai"
    assert_select "p.title", text: "Clubs"

    user
  end

  # Rails 8 authentication-based sign in
  def sign_in_as_rails8(user)
    user = users(user)
    throw "Sign-in helper needs a user" if user.nil?

    # Ensure user has password_digest set
    unless user.password_digest.present?
      user.password = "password"
      user.password_confirmation = "password"
      user.save!(validate: false)
    end

    post session_path, params: { email_address: user.email_address, password: "password" }

    assert_response :redirect
    follow_redirect!
    assert_response :success

    user
  end

  # Default sign in method (uses Devise for now, will switch to Rails 8 later)
  def sign_in_as(user)
    sign_in_as_devise(user)
  end
end

module AuthorizationHelpers
  def assert_unauthorized
    assert_equal "Vous n'êtes pas autorisé à exécuter cette action.", flash[:alert]
    assert_redirected_to root_url
  end
end

module ActionDispatch
  class IntegrationTest
    include AuthorizationHelpers
    include SignInHelper
    include Devise::Test::IntegrationHelpers
  end
end

def assert_score(expected_value, expected_hits, expected_intermediate_value, expected_intermediate_hits, actual_score)
  assert_equal expected_value, actual_score.value
  assert_equal expected_hits, actual_score.hits
  assert_equal expected_intermediate_value, actual_score.intermediate_value
  assert_equal expected_intermediate_hits, actual_score.intermediate_hits
end
