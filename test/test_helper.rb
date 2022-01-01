ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

module SignInHelper
  def sign_in_as(user)
    post user_session_path(user: { email: user.email, password: 'password' })

    assert_response :redirect
    follow_redirect!
    assert_response :success
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
  include Devise::Test::IntegrationHelpers
end