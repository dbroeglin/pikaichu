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
  # Rails 8 authentication-based sign in
  def sign_in_as(user)
    user = users(user) unless user.is_a?(User)
    throw "Sign-in helper needs a user" if user.nil?

    # Ensure user has Rails 8 auth credentials
    setup_rails8_auth_for(user)

    # For integration tests, use actual login
    if self.is_a?(ActionDispatch::IntegrationTest)
      post session_path, params: {
        email_address: user.email_address,
        password: "password"
      }
      follow_redirect! if response.redirect?
    else
      # For controller tests, set Current.session
      create_session_for(user)
    end

    user
  end

  # Alias for backward compatibility with controller tests
  alias_method :sign_in, :sign_in_as
end

# Stub authentication for controller tests
module ControllerAuthenticationStub
  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session
  end

  def authenticated?
    Current.session.present?
  end

  def current_user
    Current.user
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  def find_session_by_cookie
    nil # Controller tests use Current.session directly
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
    include Rails8AuthTestHelper
  end
end

module ActionController
  class TestCase
    include Rails8AuthTestHelper
    include SignInHelper

    # Prepend our stub to override authentication methods
    def setup
      super
      @controller.singleton_class.prepend(ControllerAuthenticationStub)
    end
  end
end

def assert_score(expected_value, expected_hits, expected_intermediate_value, expected_intermediate_hits, actual_score)
  assert_equal expected_value, actual_score.value
  assert_equal expected_hits, actual_score.hits
  assert_equal expected_intermediate_value, actual_score.intermediate_value
  assert_equal expected_intermediate_hits, actual_score.intermediate_hits
end
