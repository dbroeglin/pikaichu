require "test_helper"

class LeaderBoardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get leader_board_index_url
    assert_response :success
  end
end
