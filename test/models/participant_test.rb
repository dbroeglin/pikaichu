require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  setup do
    @participant = participating_dojos(:participating_dojo1_individual_local_12_kinteki).participants.first
    @participant.build_empty_score_and_results
  end

  test "12 results created" do
    assert_equal 12, @participant.score.results.size
  end
end
