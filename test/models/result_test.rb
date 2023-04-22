require "test_helper"

class ResultTest < ActiveSupport::TestCase
  setup do
    # TODO: we should test for teams also (teams scores are shared)
    @kinteki_participant = taikais('individual_dist_12_kinteki').participants.first
    @enteki_participant  = taikais('individual_dist_12_enteki').participants.first
    @kinteki_score = Score.new(participant: @kinteki_participant)
    @enteki_score = Score.new(participant: @enteki_participant)

    @kinteki_result = Result.new(score: @kinteki_score)
    @enteki_result = Result.new(score: @enteki_score)
  end

  test "value can be empty for kinteki" do
    assert @kinteki_result.valid?, 'should validate'
  end

  test "value cannot be empty for enteki" do
    assert @enteki_result.invalid?, 'should not validate'
    assert @enteki_result.errors.added? :value, :blank
  end

  test "marked must be true when value is set for enteki" do
    @enteki_result.assign_attributes(value: 0)

    assert @enteki_result.valid?, 'should validate'
  end

  Result::ENTEKI_VALUES.each do |value|
    test "#{value} is valid enteki value" do
      @enteki_result.assign_attributes(value: value)

      assert value.zero? && @enteki_result.status_miss? || !value.zero? && @enteki_result.status_hit?
      assert @enteki_result.valid?, 'should validate'
    end
  end

  ((0..10).to_a - Result::ENTEKI_VALUES).each do |value|
    test "#{value} is not a valid enteki value" do
      @enteki_result.assign_attributes(value: value)

      assert @enteki_result.invalid?, 'should not validate'
      assert @enteki_result.errors.added? :value, :inclusion, value: value
    end
  end

  test "rotate value 0 to 3" do
    assert_equal 3, Result.new(value: 0).rotate_value.value
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
    result = Result.new(value: 10, status: :hit)
    result.rotate_value

    assert_equal 0, result.value
    assert_equal 'miss', result.status
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

  test "kinteki finalized records cannot bet changed" do
    @kinteki_result.update(final: true)

    assert_raises(ActiveRecord::RecordInvalid) do
      @kinteki_result.update!(status: :miss)
    end
  end

  test "enteki finalized records cannot bet changed" do
    @enteki_result.update(final: true)

    assert_raises(ActiveRecord::RecordInvalid) do
      @enteki_result.update!(status: :miss)
    end
  end

  test "kinteki finalized records can be overriden" do
    @kinteki_result.update(status: :hit, final: true)
    assert_equal true, @kinteki_result.override_status(:miss)
    @kinteki_result.save!

    assert_equal true, @kinteki_result.final
    assert_equal true, @kinteki_result.overriden
    assert_equal 'miss', @kinteki_result.status
  end

  test "enteki finalized records can be overriden" do
    @enteki_result.update(value: 10, final: true)
    assert_equal true, @enteki_result.override_value(0)
    @enteki_result.save!

    assert_equal true, @enteki_result.final
    assert_equal true, @enteki_result.overriden
    assert_equal 0, @enteki_result.value
    assert_equal 'miss', @enteki_result.status
  end

  test "kinteki finalized records can be overriden but are not if no change" do
    @kinteki_result.update(status: :hit, final: true)
    assert_equal false, @kinteki_result.override_status(:hit)
    assert_equal false, @enteki_result.save

    assert_equal false, @kinteki_result.override_status('hit')
    assert_equal false, @enteki_result.save
  end

  test "enteki finalized records can be overriden but are not if no change" do
    @enteki_result.update(value: 10, final: true)
    assert_equal false, @enteki_result.override_value(10)
    assert_equal false, @enteki_result.save

    assert_equal false, @enteki_result.override_value("10")
    assert_equal false, @enteki_result.save
  end
end