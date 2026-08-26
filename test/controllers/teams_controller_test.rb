require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @participating_dojo = participating_dojos(:participating_dojo1_2in1_dist_12_kinteki)
    sign_in users(:marie_tournelle)
  end

  test "should not allow an unaffiliated user to create a team" do
    assert_no_difference "@participating_dojo.teams.count" do
      post taikai_participating_dojo_teams_url(@taikai, @participating_dojo),
           params: { team: { shortname: "Unauthorized" } }
    end

    assert_unauthorized
  end
end
