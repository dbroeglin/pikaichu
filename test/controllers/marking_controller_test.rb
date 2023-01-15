# rubocop:disable Naming/VariableNumber

require "test_helper"

class MarkingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @t = taikais(:individual_12)
    @participant = participants(:participant1_participating_dojo1_individual_12)
    @t.create_scores
  end

  test "should get show" do
    get show_marking_url @t

    puts @taikai.inspect


    assert_response :success
  end

  test "should update first result" do
    post update_marking_url @t, @participant, params: { status: 'hit' }, format: :turbo_stream
    assert_response :success
    assert_equal 'hit', @participant.results.find_by!(round: 1, index: 1).status
    @participant.results.where("round <> 1 AND index <> 1").each do |result|
      assert_nil result.status
    end
  end

  test "should refuse to update if first round not validated" do
    5.times do
      post update_marking_url @t, @participant, params: { status: 'hit' }, format: :turbo_stream
    end
    p @participant.results
    assert_response :success
    assert_equal 'hit', @participant.results.find_by!(round: 1, index: 1).status
    @participant.results.where("round <> 1 AND index <> 1").each do |result|
      assert_nil result.status
    end
  end

end
