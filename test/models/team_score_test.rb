# rubocop:disable Lint/BinaryOperatorWithIdenticalOperands

require "test_helper"

class TeamScoreTest < ActiveSupport::TestCase
  setup do
    @taikai = taikais(:"2in1_dist_12_enteki")
    @participating_dojo = participating_dojos(:participating_dojo1_2in1_dist_12_enteki)
    @team1 = teams(:a_participating_dojo1_2in1_dist_12_enteki)
    #@participant = participants(:p1_participating_dojo1_2in1_dist_12_enteki)

    @team1.participants.each do |participant|
      participant.create_empty_score_and_results
    end
    @score = @team1.create_empty_score
  end

  test "team finalized" do
    #puts @team1.to_ascii

    @team1.participants.each do |participant|
      participant.add_result(nil, 'hit', 3)
      participant.add_result(nil, 'hit', 5)
      participant.add_result(nil, 'hit', 7)
      participant.add_result(nil, 'hit', 10)
    end

    #puts @team1.to_ascii

    assert_score 0, 0, 25, 4, @team1.participants.first.score
    assert_score 0, 0, 75, 12, @team1.score

    @team1.participants.each do |participant|
      participant.finalize_round(1, nil)
    end

    assert_not @team1.score.finalized?

    (2..3).each.each do |index|
      @team1.participants.each do |participant|
        participant.add_result(nil, 'hit', 3)
        participant.add_result(nil, 'hit', 5)
        participant.add_result(nil, 'hit', 7)
        participant.add_result(nil, 'hit', 10)
        participant.finalize_round(index, nil)
      end
    end

    assert @team1.score.finalized?
  end
end

