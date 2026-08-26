require "test_helper"
require "taikais_test_helpers"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  include TaikaisTestHelpers

  setup do
    @taikai = taikais(:matches_dist_4_kinteki)
    @match = @taikai.matches.first
    sign_in users(:marie_tournelle)
  end

  test "should not allow an unaffiliated user to update a match" do
    patch taikai_match_url(@taikai, @match),
          params: { match: { winner: @match.winner } }

    assert_unauthorized
  end

  test "should allow assigned marking staff to view the match board" do
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :marking)
    sign_in users(:alain_terieur)

    get taikai_matches_url(@taikai)

    assert_response :success
  end

  test "should scope a match to the tournament in the route" do
    other_match = taikais(:matches_local_4_kinteki).matches.first
    sign_in users(:jean_bon)

    patch taikai_match_url(@taikai, other_match),
          params: { match: { winner: other_match.winner } }

    assert_response :not_found
  end
end
