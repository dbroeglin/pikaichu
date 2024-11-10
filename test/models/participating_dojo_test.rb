require "test_helper"
require 'taikais_test_helpers'

class ParticipatingDojoTest < ActiveSupport::TestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    @taikai = taikais(:'2in1_dist_12_enteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :registration)
  end

  test "draw" do
    participating_dojo = @taikai.participating_dojos.first

    participating_dojo.draw

    assert_equal 1, participating_dojo.teams.first.index
    assert_equal 2, participating_dojo.teams.second.index
    assert_equal 1, participating_dojo.teams.first.participants.first.index
    assert_equal 2, participating_dojo.teams.first.participants.second.index
    assert_equal 3, participating_dojo.teams.first.participants.third.index
    assert_equal 4, participating_dojo.teams.second.participants.first.index
    assert_equal 5, participating_dojo.teams.second.participants.second.index
    assert_equal 6, participating_dojo.teams.second.participants.third.index
  end
end
