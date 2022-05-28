require "test_helper"

class ScoreTest < ActiveSupport::TestCase
  test "comparison" do
    assert_equal -1, Score::new(0, 0) <=> Score::new(1, 3)
    assert_equal 0,  Score::new(0, 0) <=> Score::new(0, 0)
    assert_equal 1,  Score::new(1, 3) <=> Score::new(0,0)

    assert_equal -1, Score::new(1, 10) <=> Score::new(2, 10)
  end
end
