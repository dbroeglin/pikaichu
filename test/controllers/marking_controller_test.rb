require "test_helper"
require "taikais_test_helpers"

class MarkingControllerTest < ActionDispatch::IntegrationTest
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_dist_12_kinteki)
    @taikai.current_user = users(:jean_bon) # for transitions
    @participant = @taikai.participating_dojos.first.participants.first
  end

  test "jean should have access to marking" do
    get show_marking_url @taikai

    assert_response :redirect

    transition_taikai_to(@taikai, :marking)

    get show_marking_url @taikai
    assert_response :success

    assert_select "h1", "Feuille de marque - #{@taikai.shortname}"
    assert_select "tbody tr th", "Participating Dojo1 Individual Dist 12 Kinteki"
    assert_select "tbody tr:nth-of-type(13) th", "Participating Dojo2 Individual Dist 12 Kinteki"
  end

  test "alain_terieur should have access to marking for participating dojo 1" do
    get show_marking_url @taikai

    assert_response :redirect

    transition_taikai_to(@taikai, :marking)

    sign_in users(:alain_terieur)
    get show_marking_url @taikai

    assert_response :success
    assert_select "h1", "Feuille de marque - #{@taikai.shortname}"
    assert_select "tbody th", "Participating Dojo1 Individual Dist 12 Kinteki"
    assert_select "tbody tr:nth-of-type(4) th", 0
  end

  test "marie should not have access to marking" do
    get show_marking_url @taikai

    assert_response :redirect

    transition_taikai_to(@taikai, :marking)

    sign_in users(:marie_tournelle)

    get show_marking_url @taikai
    assert_response :redirect
  end

  test "should update first result" do
    transition_taikai_to(@taikai, :marking)
    post update_marking_url @taikai, @participant, params: { status: "hit" }, format: :turbo_stream
    assert_response :success

    assert_equal "hit", @participant.score.results.find_by!(round: 1, index: 1).status
    @participant.score.results.where("round <> 1 AND index <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should refuse to update if first round not validated" do
    transition_taikai_to(@taikai, :marking)

    5.times do
      post update_marking_url @taikai, @participant, params: { status: "hit" }, format: :turbo_stream
      assert_response :success
      assert_match dom_id(@participant), @response.body
    end

    @participant.score.results.where("round = 1").each do |result|
      assert_equal "hit", result.status
    end
    @participant.score.results.where("round <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should rotate first result" do
    transition_taikai_to(@taikai, :marking)

    result = @participant.score.results.find_by!(round: 1, index: 1)
    result.update!(status: "hit")
    patch rotate_marking_url @taikai, @participant, result.id, params: { round: 1 }, format: :turbo_stream
    assert_response :success
    assert_equal "miss", @participant.score.results.find_by!(round: 1, index: 1).status
  end

  test "should not allow an unaffiliated user to rotate a result" do
    transition_taikai_to(@taikai, :marking)
    result = @participant.score.results.find_by!(round: 1, index: 1)
    result.update!(status: "hit")
    sign_in users(:marie_tournelle)

    patch rotate_marking_url(@taikai, @participant, result.id, format: :turbo_stream),
          params: { round: 1 }

    assert_unauthorized
    assert_equal "hit", result.reload.status
  end

  test "should finalize first round" do
    transition_taikai_to(@taikai, :marking)

    4.times do
      post update_marking_url @taikai, @participant, params: { status: "hit" }, format: :turbo_stream
      assert_response :success
      assert_match dom_id(@participant), @response.body
    end

    patch finalize_round_marking_url @taikai, @participant, params: { round: "1" }, format: :turbo_stream

    @participant.score.results.where("round = 1").each do |result|
      assert_equal "hit", result.status
      assert_equal true, result.final
    end
    @participant.score.results.where("round <> 1").each do |result|
      assert_nil result.status
      assert_equal false, result.final
    end
  end

  test "should not allow an unaffiliated user to finalize a round" do
    transition_taikai_to(@taikai, :marking)
    results = @participant.score.results.where(round: 1)
    results.update_all(status: "hit")
    sign_in users(:marie_tournelle)

    patch finalize_round_marking_url(@taikai, @participant, format: :turbo_stream),
          params: { round: "1" }

    assert_unauthorized
    assert results.reload.none?(&:final)
  end

  test "should not allow a dojo administrator to mark another dojo" do
    transition_taikai_to(@taikai, :marking)
    other_participant = @taikai.participating_dojos.second.participants.first
    sign_in users(:alain_terieur)

    post update_marking_url(@taikai, other_participant, format: :turbo_stream),
         params: { status: "hit" }

    assert_response :not_found
    assert other_participant.score.results.none?(&:marked?)
  end
end
