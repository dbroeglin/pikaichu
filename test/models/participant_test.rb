# rubocop:disable Naming/VariableNumber

require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  setup do
    @participant = participants(:participant1_participating_dojo1_individual_12)
    @participant.create_empty_score_and_results
  end

  test "12 results created" do
    assert_equal 12, @participant.results.size
  end

end
