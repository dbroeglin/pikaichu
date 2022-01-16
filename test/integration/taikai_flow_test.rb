require "test_helper"

class TaikaiFlowTest < ActionDispatch::IntegrationTest
  setup do
    # @article = articles(:one)
  end

  test "redirected to sign in page" do
    get root_path

    assert_response :redirect
    follow_redirect!

    assert_response :success
    assert_select "p.card-header-title", "Log in"
  end

  test "taikai list" do
    sign_in_as(users(:jean_bon))

    assert_select "p.title", text: "Taikais"
    assert_select "p.title", text: "Dojos"
  end


  # called after every single test
  teardown do
    # when controller is using cache it may be a good idea to reset it afterwards
    Rails.cache.clear
  end
end