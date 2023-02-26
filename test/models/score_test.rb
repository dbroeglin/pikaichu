# rubocop:disable Lint/BinaryOperatorWithIdenticalOperands

require "test_helper"

class ScoreTest < ActiveSupport::TestCase
  setup do
    @score = scores(:score1_participant1_AK_2in1_test)
    @score.create_results 3, 4
  end

  test "comparison" do
    assert_equal(0,  Score::ScoreValue.new(hits: 0, value: 0)  <=> Score::ScoreValue.new(hits: 0, value: 0))
    assert_equal(-1, Score::ScoreValue.new(hits: 0, value: 0)  <=> Score::ScoreValue.new(hits: 1, value: 3))
    assert_equal(1,  Score::ScoreValue.new(hits: 1, value: 3)  <=> Score::ScoreValue.new(hits: 0, value: 0))
    assert_equal(-1, Score::ScoreValue.new(hits: 1, value: 10) <=> Score::ScoreValue.new(hits: 2, value: 10))
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

  test "finalized?" do
    @score.results.update_all(status: 'miss')
    @score.results.reload
    assert_not @score.finalized?

    @score.results.update_all(final: true)
    @score.results.reload
    assert @score.finalized?
  end


  test "previous_round_finalized? is true for 2.1 if 1.x are finalized" do
    @score.results.round(1).update_all(status: 'miss', final: true)
    @score.results.reload

    result = @score.results.first_empty
    assert @score.previous_round_finalized?(result)
  end

  test "update works for 2.1 if 1.x are finalized" do
    @score.results.round(1).each { |result| result.update!(status: 'hit', final: true) }
    assert_score 0, 4, 0, 4, @score

    result = @score.add_result :hit
    assert_score 0, 4, 0, 5, @score
  end

  test "update fails for 2.1 if 1.x are not finalized" do
    @score.results.round(1).each { |result| result.update!(status: 'hit', final: false) }
    assert_score 0, 0, 0, 4, @score

    assert_raises Score::PreviousRoundNotValidatedError do
      @score.add_result :hit
    end
    assert_score 0, 0, 0, 4, @score
  end

  test "addition of ScoreValue vith hits and value" do
    score1 = Score::ScoreValue.new(hits: 1, value: 2)
    score2 = Score::ScoreValue.new(hits: 3, value: 4)

    assert_equal Score::ScoreValue.new(hits: 4, value: 6), score1 + score2
  end

  test "addition of ScoreValue vith hits only" do
    score1 = Score::ScoreValue.new(hits: 1)
    score2 = Score::ScoreValue.new(hits: 3)

    assert_equal Score::ScoreValue.new(hits: 4), score1 + score2
  end
end
