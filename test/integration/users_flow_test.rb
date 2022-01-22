require "test_helper"

class UsersFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:jean_bon)
  end

  test "redirected to sign in page" do
    get root_path

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "p.card-header-title", "Connexion"
  end

  test "disconnect" do
    sign_in_as(:jean_bon)

    delete destroy_user_session_path
    assert_response :redirect
  end

  # called after every single test
  teardown do
    # when controller is using cache it may be a good idea to reset it afterwards
    Rails.cache.clear
  end
end