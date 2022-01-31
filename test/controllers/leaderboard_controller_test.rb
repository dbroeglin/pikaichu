require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual12)
  end

  test "should get show" do
    get leaderboard_taikai_url @taikai
    assert_response :success
  end
end
