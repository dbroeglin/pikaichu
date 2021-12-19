require "test_helper"

class JudgingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get judging_index_url
    assert_response :success
  end

  test "should get update" do
    get judging_update_url
    assert_response :success
  end
end
