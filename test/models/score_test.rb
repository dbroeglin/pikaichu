# rubocop:disable Lint/BinaryOperatorWithIdenticalOperands

require "test_helper"

class ScoreTest < ActiveSupport::TestCase
  test "comparison" do
    assert_equal(0,  Score.new(hits: 0, value: 0)  <=> Score.new(hits: 0, value: 0))
    assert_equal(-1, Score.new(hits: 0, value: 0)  <=> Score.new(hits: 1, value: 3))
    assert_equal(1,  Score.new(hits: 1, value: 3)  <=> Score.new(hits: 0, value: 0))
    assert_equal(-1, Score.new(hits: 1, value: 10) <=> Score.new(hits: 2, value: 10))
  end
end
