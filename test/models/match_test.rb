require "test_helper"

class MatchTest < ActiveSupport::TestCase
  setup do
    @taikai = taikais(:matches_dist_4_enteki)

    @participating_dojo = @taikai.participating_dojos.first
    @team1 = @participating_dojo.teams[0]
    @team2 = @participating_dojo.teams[1]
    @team3 = @participating_dojo.teams[2]

    @match = Match.find_by(taikai_id: @taikai.id, level: 2, index: 1).build_empty_score_and_results
    @match.update(
      team1_id: @team1.id,
      team2_id: @team2.id
    )
    @target_match1 = Match.find_by(taikai_id: @taikai.id, level: 1, index: 1).build_empty_score_and_results
    @target_match2 = Match.find_by(taikai_id: @taikai.id, level: 1, index: 2).build_empty_score_and_results
  end

  test "select winner in quarter finals" do
    generate_results
    finalize_results

    @match.select_winner 1
    @target_match1.reload
    @target_match2.reload

    assert_equal @team1, @target_match1.team1
    assert_score 0, 0, 0, 0, @target_match1.score(1)
    assert_nil @target_match1.score(2)

    assert_equal @team2, @target_match2.team1
    assert_score 0, 0, 0, 0, @target_match2.score(1)
    assert_nil @target_match2.score(2)
  end

  test "finalize" do
    assert_score 0, 0, 0, 0, @match.score(1)
    assert_score 0, 0, 0, 0, @match.score(2)

    generate_results

    assert_score 0, 0, 36, 12, @match.score(1)
    assert_score 0, 0, 36, 12, @match.score(2)

    @match.team1.participants.each do |participant|
      participant.finalize_round 1, @match.id
    end

    assert_score 36, 12, 36, 12, @match.score(1)
    assert_score 0, 0, 36, 12, @match.score(2)

    @match.team2.participants.each do |participant|
      participant.finalize_round 1, @match.id
    end

    assert_score 36, 12, 36, 12, @match.score(1)
    assert_score 36, 12, 36, 12, @match.score(2)
  end

  test "marking" do
    assert_equal 0, @match.score(1).hits

    @team1.participants.first.add_result(@match.id, :hit, 3)
    @team1.participants.second.add_result(@match.id, :miss, 0)
    @team1.participants.last.add_result(@match.id, :hit, 10)

    @team2.participants.last.add_result(@match.id, :hit, 5)

    assert_not_nil @match.score(1)
    assert_equal 0, @match.score(1).hits
    assert_equal 2, @match.score(1).intermediate_hits
    assert_equal 0, @match.score(1).value
    assert_equal 13, @match.score(1).intermediate_value

    assert_not_nil @match.score(2)
    assert_equal 0, @match.score(2).hits
    assert_equal 0, @match.score(2).value
    assert_equal 1, @match.score(2).intermediate_hits
    assert_equal 5, @match.score(2).intermediate_value
  end

  test "team create" do
    assert_equal 3, @team1.participants.count
    assert_equal 3, @team2.participants.count
    assert_equal @team1, @match.team1
    assert_equal @team2, @match.team2

    (1..2).each do |index|
      assert_not_nil @match.score(index)
      assert_equal @match.team(index), @match.score(index).team
      @match.team(index).participants.each do |participant|
        assert_equal 4, participant.score(@match.id).results.count
      end
    end
  end

  test "swap teams" do
    @match.team1_id = @team2.id
    @match.team2_id = @team1.id
    @match.save!

    assert_equal @team2, @match.team1
    assert_equal @team1, @match.team2

    (1..2).each do |index|
      assert_not_nil @match.score(index)
      assert_equal @match.team(index), @match.score(index).team
      @match.team(index).participants.each do |participant|
        assert_equal 4, participant.score(@match.id).results.count
      end
    end
  end

  test "change team1" do
    @match.team1_id = @team3.id
    @match.save!

    assert_equal @team3, @match.team1
    assert_equal @team2, @match.team2

    (1..2).each do |index|
      assert_not_nil @match.score(index)
      assert_equal @match.team(index), @match.score(index).team
      @match.team(index).participants.each do |participant|
        assert_equal 4, participant.score(@match.id).results.count
      end
    end
  end

  test "change team2" do
    assert_equal @team1, @match.team1
    assert_equal @team2, @match.team2

    @match.team2_id = @team3.id
    @match.save!

    assert_equal @team1, @match.team1
    assert_equal @team3, @match.team2

    (1..2).each do |index|
      assert_not_nil @match.score(index)
      assert_equal @match.team(index), @match.score(index).team
      @match.team(index).participants.each do |participant|
        assert_equal 4, participant.score(@match.id).results.count
      end
    end
  end

  def finalize_results; end

  def generate_results
    @match.team1.participants.each do |participant|
      4.times { participant.add_result(@match.id, :hit, 3) }
    end

    @match.team2.participants.each do |participant|
      4.times { participant.add_result(@match.id, :hit, 3) }
    end
  end
end
