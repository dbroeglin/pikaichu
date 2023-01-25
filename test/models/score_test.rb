# rubocop:disable Lint/BinaryOperatorWithIdenticalOperands

require "test_helper"

class ScoreTest < ActiveSupport::TestCase
  setup do
    @score = scores(:score1_participant1_AK_2in1_test)
    @score.create_results 3, 4
  end

  test "comparison" do
    assert_equal(0,  Score.new(hits: 0, value: 0)  <=> Score.new(hits: 0, value: 0))
    assert_equal(-1, Score.new(hits: 0, value: 0)  <=> Score.new(hits: 1, value: 3))
    assert_equal(1,  Score.new(hits: 1, value: 3)  <=> Score.new(hits: 0, value: 0))
    assert_equal(-1, Score.new(hits: 1, value: 10) <=> Score.new(hits: 2, value: 10))
  end

  test "marking?" do
    assert_not(Score.new(hits: 0, value: 0).marking?)
  end


  test "first_empty is first" do
    result = @score.results.first_empty

    assert_equal 1, result.round
    assert_equal 1, result.index
  end

  test "first_empty in next round" do
    @score.results.round(1).update_all(status: 'hit')
    @score.results.reload

    result = @score.results.first_empty

    assert_equal 2, result.round
    assert_equal 1, result.index
  end

  test "first_empty returns nil when none" do
    @score.results.update_all(status: 'miss')
    @score.results.reload

    result = @score.results.first_empty

    assert_nil result
  end

  test "previous_round_finalized? is true when first result" do
    result = @score.results.first_empty
    assert @score.previous_round_finalized? result
  end

  test "previous_round_finalized? is false for 2.1 if 1.x are not finalized" do
    @score.results.round(1).update_all(status: 'miss')
    @score.results.reload

    result = @score.results.first_empty
    assert_not @score.previous_round_finalized?(result)
  end

  test "previous_round_finalized? is true for 2.1 if 1.x are finalized" do
    @score.results.round(1).update_all(status: 'miss', final: true)
    @score.results.reload

    result = @score.results.first_empty
    assert @score.previous_round_finalized?(result)
  end

  test "update works for 2.1 if 1.x are finalized" do
    @score.results.round(1).each { |result| result.update!(status: 'hit', final: true) }
    assert_equal 4, @score.hits

    result = @score.add_result :hit
    assert_equal 5, @score.hits
  end

  test "update fails for 2.1 if 1.x are not finalized" do
    @score.results.round(1).each { |result| result.update!(status: 'hit', final: false) }
    assert_equal 4, @score.hits

    assert_raises Score::PreviousRoundNotValidatedError do
      @score.add_result :hit
    end
    assert_equal 4, @score.hits
  end
end
