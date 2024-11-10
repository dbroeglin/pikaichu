require "test_helper"
require 'taikais_test_helpers'

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
    post update_marking_url @taikai, @participant, params: { status: 'hit' }, format: :turbo_stream
    assert_response :success

    assert_equal 'hit', @participant.score.results.find_by!(round: 1, index: 1).status
    @participant.score.results.where("round <> 1 AND index <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should refuse to update if first round not validated" do
    transition_taikai_to(@taikai, :marking)

    5.times do
      post update_marking_url @taikai, @participant, params: { status: 'hit' }, format: :turbo_stream
      assert_response :success
      assert_match dom_id(@participant), @response.body
    end

    @participant.score.results.where("round = 1").each do |result|
      assert_equal 'hit', result.status
    end
    @participant.score.results.where("round <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should rotate first result" do
    transition_taikai_to(@taikai, :marking)

    result = @participant.score.results.find_by!(round: 1, index: 1)
    result.update!(status: 'hit')
    patch rotate_marking_url @taikai, @participant, result.id, params: { round: 1 }, format: :turbo_stream
    assert_response :success
    assert_equal 'miss', @participant.score.results.find_by!(round: 1, index: 1).status
  end

  test "should finalize first round" do
    transition_taikai_to(@taikai, :marking)

    4.times do
      post update_marking_url @taikai, @participant, params: { status: 'hit' }, format: :turbo_stream
      assert_response :success
      assert_match dom_id(@participant), @response.body
    end

    patch finalize_round_marking_url @taikai, @participant, params: { round: '1' }, format: :turbo_stream

    @participant.score.results.where("round = 1").each do |result|
      assert_equal 'hit', result.status
      assert_equal true, result.final
    end
    @participant.score.results.where("round <> 1").each do |result|
      assert_nil result.status
      assert_equal false, result.final
    end
  end
end
