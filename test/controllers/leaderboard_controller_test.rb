# rubocop:disable Naming/VariableNumber

require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_dist_12_kinteki)
    @taikai.current_user = users(:jean_bon)
  end

  test "should get show" do
    @taikai.transition_to! :registration
    @taikai.transition_to! :marking

    get leaderboard_taikai_url @taikai

    assert_response :success
  end
end
