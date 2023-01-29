# rubocop:disable Naming/VariableNumber

require "test_helper"

class MarkingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_12)
    @participant = participants(:participant1_participating_dojo1_individual_12).reload
  end

  test "should get show" do
    get show_marking_url @taikai

    assert_response :success

    assert_select "h1", "Feuille de marque - #{@taikai.shortname}"
  end

  test "should update first result" do
    @taikai.transition_to! :registration
    @taikai.transition_to! :marking
    post update_marking_url @taikai, @participant, params: { status: 'hit' }, format: :turbo_stream
    assert_response :success

    assert_equal 'hit', @participant.results.find_by!(round: 1, index: 1).status
    @participant.results.where("round <> 1 AND index <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should refuse to update if first round not validated" do
    @taikai.transition_to! :registration
    @taikai.transition_to! :marking

    5.times do
      post update_marking_url @taikai, @participant, params: { status: 'hit' }, format: :turbo_stream
      assert_response :success
      assert_match dom_id(@participant), @response.body
    end

    @participant.results.where("round = 1").each do |result|
      assert_equal 'hit', result.status
    end
    @participant.results.where("round <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should rotate first result" do
    @taikai.transition_to! :registration
    @taikai.transition_to! :marking

    result = @participant.results.find_by!(round: 1, index: 1)
    result.update!(status: 'hit')
    patch rotate_marking_url @taikai, @participant, result.id, params: { round: 1 }, format: :turbo_stream
    assert_response :success
    assert_equal 'miss', @participant.results.find_by!(round: 1, index: 1).status
  end

  test "should finalize first round" do
    @taikai.transition_to! :registration
    @taikai.transition_to! :marking

    4.times do
      post update_marking_url @taikai, @participant, params: { status: 'hit' }, format: :turbo_stream
      assert_response :success
      assert_match dom_id(@participant), @response.body
    end

    patch finalize_round_marking_url @taikai, @participant, params: { round: '1' }, format: :turbo_stream

    @participant.results.where("round = 1").each do |result|
      assert_equal 'hit', result.status
      assert_equal true, result.final
    end
    @participant.results.where("round <> 1").each do |result|
      assert_nil result.status
      assert_equal false, result.final
    end
  end
end
