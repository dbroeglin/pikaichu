# rubocop:disable Naming/VariableNumber

require "test_helper"

class ResultTest < ActiveSupport::TestCase
  setup do
    @kinteki_participant = participants(:participant_participating_dojo_2in1_12)
    @enteki_participant  = participants(:participant_participating_dojo_2in1_12_enteki)
    @kinteki_score = Score.new(participant: @kinteki_participant)
    @enteki_score = Score.new(participant: @enteki_participant)
  end

  test "value can be empty for kinteki" do
    result = Result.new(participant: @kinteki_participant, score: @kinteki_score)

    assert result.valid?, 'should validate'
  end

  test "value cannot be empty for enteki" do
    result = Result.new(participant: @enteki_participant, score: @enteki_score)

    assert result.invalid?, 'should not validate'
    assert result.errors.added? :value, :blank
  end

  test "marked must be true when value is set for enteki" do
    result = Result.new(participant: @enteki_participant, score: @enteki_score, value: 0)

    assert result.valid?, 'should validate'
  end

  Result::ENTEKI_VALUES.each do |value|
    test "#{value} is valid enteki value" do
      result = Result.new(participant: @enteki_participant, score: @enteki_score, value: value)

      assert value.zero? && result.status_miss? || !value.zero? && result.status_hit?
      assert result.valid?, 'should validate'
    end
  end

  ((0..10).to_a - Result::ENTEKI_VALUES).each do |value|
    test "#{value} is not a valid enteki value" do
      result = Result.new(participant: @enteki_participant, score: @enteki_score, value: value)

      assert result.invalid?, 'should not validate'
      assert result.errors.added? :value, :inclusion, value: value
    end
  end

  test "rotate value 0 to 3" do
    assert_equal 3, Result.new( value: 0).rotate_value.value
  end

  test "rotate value 3 to 5" do
    assert_equal 5, Result.new(value: 3).rotate_value.value
  end

  test "rotate value 5 to 7" do
    assert_equal 7, Result.new(value: 5).rotate_value.value
  end

  test "rotate value 7 to 9" do
    assert_equal 9, Result.new(value: 7).rotate_value.value
  end

  test "rotate value 9 to 10" do
    assert_equal 10, Result.new(value: 9).rotate_value.value
  end

  test "rotate value 10 to 0" do
    assert_equal 0, Result.new(value: 10).rotate_value.value
  end

  test "rotate status hit to miss when partial round" do
    assert_equal 'miss', Result.new(status: 'hit').rotate_status(false).status
  end

  test "rotate status miss to unknown when partial round" do
    assert_equal 'unknown', Result.new(status: 'miss').rotate_status(false).status
  end

  test "rotate status unknown to hit when partial round" do
    assert_equal 'hit', Result.new(status: 'unknown').rotate_status(false).status
  end

  test "rotate status hit to miss when full round" do
    assert_equal 'miss', Result.new(status: 'hit').rotate_status(true).status
  end

  test "rotate status miss to hit when full round" do
    assert_equal 'hit', Result.new(status: 'miss').rotate_status(true).status
  end

  test "rotate status unknown to hit when full round" do
    assert_equal 'hit', Result.new(status: 'unknown').rotate_status(true).status
  end
end
