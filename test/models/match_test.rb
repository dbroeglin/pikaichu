require "test_helper"

class MatchTest < ActiveSupport::TestCase
  setup do
    @taikai = taikais(:matches_dist_4_enteki)
    @participating_dojo = participating_dojos(:participating_dojo1_matches_dist_4_enteki)
    @team1 = teams(:a_participating_dojo1_matches_dist_4_enteki)
    @team2 = teams(:b_participating_dojo1_matches_dist_4_enteki)
    @team3 = teams(:c_participating_dojo1_matches_dist_4_enteki)

    @match = Match.create(
      taikai_id: @taikai.id,
      team1_id: @team1.id,
      team2_id: @team2.id,
      level: 1,
      index: 1)
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

end
