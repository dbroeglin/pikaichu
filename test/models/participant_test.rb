require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  setup do
    @participant = participants(:participant1_participating_dojo1_individual12)
    @participant.create_empty_results
  end

  test "12 results created" do
    assert_equal 12, @participant.results.size
  end

  test "first_empty is first" do
    result = @participant.results.first_empty

    assert_equal 1, result.round
    assert_equal 1, result.index
  end

  test "first_empty in next round" do
    @participant.results.round(1).update_all(status: 'hit')
    @participant.results.reload

    result = @participant.results.first_empty

    assert_equal 2, result.round
    assert_equal 1, result.index
  end

  test "first_empty returns nil when none" do
    @participant.results.update_all(status: 'miss')
    @participant.results.reload

    result = @participant.results.first_empty

    assert_nil result
  end

  test "previous_round_finalized? is true when first result" do
    result = @participant.results.first_empty
    assert @participant.previous_round_finalized? result
  end

  test "previous_round_finalized? is false for 2.1 if 1.x are not finalized" do
    @participant.results.round(1).update_all(status: 'miss')
    @participant.results.reload

    result = @participant.results.first_empty
    assert_not @participant.previous_round_finalized?(result)
  end

  test "previous_round_finalized? is true for 2.1 if 1.x are finalized" do
    @participant.results.round(1).update_all(status: 'miss', final: true)
    @participant.results.reload

    result = @participant.results.first_empty
    assert @participant.previous_round_finalized?(result)
  end
end
