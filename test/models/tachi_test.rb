require "test_helper"
require 'taikais_test_helpers'

class TachiTest < ActiveSupport::TestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :marking)
  end

  test "initial tachi has index 1 and round 1" do
    @taikai.participating_dojos.each do |participating_dojo|
      assert_not_nil participating_dojo.current_tachi
      assert_equal false, participating_dojo.current_tachi.finished
      assert_equal 1, participating_dojo.current_tachi.index
      assert_equal 1, participating_dojo.current_tachi.round
    end
  end

  test "participants of each tachi" do
    @taikai.participating_dojos.each do |participating_dojo|
      participating_dojo.tachis.each do |tachi|
        participants = participating_dojo.participants
                                         .order(:index)[((tachi.index - 1) * @taikai.num_targets)..(tachi.index * @taikai.num_targets - 1)]
        assert_equal participants, tachi.participants
      end
    end
  end

  test "wrong order tachis still works" do
    participating_dojo = @taikai.participating_dojos.first

    participating_dojo.tachis.where(index: 1).each do |tachi|
      assert_equal false, tachi.finished
      tachi.participants.first(@taikai.num_targets).each do |participant|
        score = participant.scores.first
        score.results.where(final: false).first(@taikai.num_arrows).each do |result|
          result.update!(status: 'hit', value: 3)
        end
        score.finalize_round(tachi.round)
      end

      tachi.reload
      assert_equal true, tachi.finished
    end
  end

  test "finish all tachis" do
    participating_dojo = @taikai.participating_dojos.first

    while (tachi = participating_dojo.current_tachi)
      assert_equal false, tachi.finished
      tachi.participants.first(@taikai.num_targets).each do |participant|
        score = participant.scores.first
        score.results.where(final: false).first(@taikai.num_arrows).each do |result|
          result.update!(status: 'hit', value: 3)
        end
        score.finalize_round(tachi.round)
      end

      tachi.reload
      assert_equal true, tachi.finished
    end
  end

  test "initial tachi is finished" do
    participating_dojo = @taikai.participating_dojos.first

    participating_dojo.teams.map(&:participants).flatten.first(@taikai.num_targets).each do |participant|
      score = participant.scores.first
      score.results.first(@taikai.num_arrows).each do |result|
        result.update!(status: 'hit', value: 3)
      end
      score.finalize_round(1)
    end

    assert_equal true, participating_dojo.tachis.first.finished

    tachi = participating_dojo.current_tachi
    assert_not_nil tachi
    assert_equal false, tachi.finished
    assert_equal 2, tachi.index
    assert_equal 1, tachi.round
  end
end
