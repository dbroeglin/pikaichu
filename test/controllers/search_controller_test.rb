require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "should get user" do
    get search_user_url
    assert_response :success
  end
end
