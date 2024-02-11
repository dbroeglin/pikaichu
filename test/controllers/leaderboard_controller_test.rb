require "test_helper"

class LeaderboardControllerTest < ActionDispatch::IntegrationTest
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_dist_12_kinteki)
    @taikai.current_user = users(:jean_bon)
  end

  TAIKAI_DATA.each do |form, distributed, total_num_arrows, scoring|
    dist = distributed ? :distributed : :local
    test "#{form} #{dist} #{total_num_arrows} #{scoring} should get show" do
      @taikai = Taikai.find_by(form: form,
                               distributed: distributed,
                               total_num_arrows: total_num_arrows,
                               scoring: scoring)
      @taikai.current_user = users(:jean_bon)

      @taikai.transition_to! :registration
      @taikai.transition_to! :marking

      get leaderboard_taikai_url @taikai
      assert_response :success

      get leaderboard_public_taikai_url @taikai
      assert_response :success
    end
  end
end
