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

  test "tachi for matches taikai" do
    @taikai = taikais('matches_dist_4_kinteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :marking)
    @taikai.participating_dojos.each do |participating_dojo|
      assert_not_nil participating_dojo.current_tachi
      assert_equal false, participating_dojo.current_tachi.finished
      assert_equal 1, participating_dojo.current_tachi.index
      assert_equal 3, participating_dojo.current_tachi.match.level
      assert_equal 1, participating_dojo.current_tachi.match.index
    end
  end

  test "tachi is finished when match is decided" do
    @taikai = taikais('matches_dist_4_kinteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :marking)
    participating_dojo = @taikai.participating_dojos.first

    @taikai.matches.where(level: 3).each do |match|
      tachi = participating_dojo.current_tachi
      assert_equal match, tachi.match
      match.select_winner(1)
      tachi.reload
      assert_equal true, tachi.finished
      assert_not_nil participating_dojo.current_tachi
      assert_equal false, participating_dojo.current_tachi.finished
      assert_not_equal tachi, participating_dojo.current_tachi
      assert_participants(tachi, match)
    end
    @taikai.matches.where(level: 2).each do |match|
      tachi = participating_dojo.current_tachi
      assert_equal match, tachi.match
      match.select_winner(1)
      tachi.reload
      assert_equal true, tachi.finished
      assert_not_nil participating_dojo.current_tachi
      assert_equal false, participating_dojo.current_tachi.finished
      assert_not_equal tachi, participating_dojo.current_tachi
      assert_participants(tachi, match)
    end
    (final, semi_final) = @taikai.matches.where(level: 1)
    tachi = participating_dojo.current_tachi
    assert_equal semi_final, tachi.match
    tachi.match.select_winner(1)
    tachi.reload
    assert_equal true, tachi.finished
    assert_participants(tachi, semi_final)

    tachi = participating_dojo.current_tachi
    assert_equal final, tachi.match
    tachi.match.select_winner(1)
    tachi.reload
    assert_equal true, tachi.finished
    assert_participants(tachi, final)
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

  private

  def assert_participants(tachi, match)
    i = -1
    assert_equal match.team1.participants[0], tachi.participants[i += 1]
    assert_equal match.team1.participants[1], tachi.participants[i += 1]
    assert_equal match.team1.participants[2], tachi.participants[i += 1]
    assert_equal match.team2.participants[0], tachi.participants[i += 1]
    assert_equal match.team2.participants[1], tachi.participants[i += 1]
    assert_equal match.team2.participants[2], tachi.participants[i += 1]
  end
end
