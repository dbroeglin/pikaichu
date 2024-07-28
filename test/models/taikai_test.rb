require "test_helper"
require 'taikais_test_helpers'

class TaikaiTest < ActiveSupport::TestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    @taikai = taikais(:'2in1_dist_12_enteki')
    @taikai.current_user = users(:jean_bon)
  end

  TAIKAI_DATA.each do |form, distributed, total_num_arrows, scoring|
    dist = distributed ? :distributed : :local
    next unless distributed

    test "#{form} #{dist} #{total_num_arrows} #{scoring} validates" do
      @taikai.scoring = scoring
      @taikai.distributed = distributed
      @taikai.form = form
      @taikai.total_num_arrows = total_num_arrows
      @taikai.save!
    end
  end

  [
    [:kinteki, :individual, 6],
    [:kinteki, :team,       6],
    [:kinteki, :'2in1',     6],
    [:kinteki, :individual, 13],
    [:kinteki, :team,       13],
    [:kinteki, :'2in1',     13],
    [:kinteki, :matches,    12],
    [:enteki,  :matches,    12],
  ].each do |scoring, form, total_num_arrows|
    test "#{scoring} #{form} #{total_num_arrows} does not validate" do
      @taikai.scoring = scoring
      @taikai.form = form
      @taikai.total_num_arrows = total_num_arrows
      assert_raises ActiveRecord::RecordInvalid do
        @taikai.save!
      end
    end
  end

  %i[2in1 matches individual team].each do |form|
    test "transitions for #{form}" do
      @taikai.form = form
      @taikai.total_num_arrows = form == :matches ? 4 : 12
      @taikai.save!
      @taikai.transition_to!(:registration)
      @taikai.transition_to!(:marking)
      TestDataService.finalize_scores(@taikai)
      @taikai.transition_to!(:tie_break)
      @taikai.transition_to!(:done)
    end
  end

  test "cannot change once done" do
    @taikai.form = :'2in1'
    @taikai.transition_to!(:registration)
    @taikai.transition_to!(:marking)
    TestDataService.finalize_scores(@taikai)
    @taikai.transition_to!(:tie_break)
    @taikai.transition_to!(:done)

    # TODO: test that we cannot change the form, scoring, etc.
  end

  test "cannot create part two without enough teams" do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    @taikai.transition_to!(:registration)
    @taikai.teams.last.destroy!
    @taikai.transition_to!(:marking)
    generate_taikai_results(@taikai)
    @taikai.transition_to!(:tie_break)
    @taikai.transition_to!(:done)
    new_taikai = Taikai.create_from_2in1(@taikai.id, users(:jean_bon), "part2", "partie 2", 8)

    assert_equal :not_enough_teams, new_taikai.errors.details[:base].first[:error]
  end

  test "cannot create part two without enough non-mixed teams" do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    @taikai.transition_to!(:registration)
    @taikai.teams.each { |team| team.update(mixed: true) }
    @taikai.transition_to!(:marking)
    generate_taikai_results(@taikai)
    @taikai.transition_to!(:tie_break)
    @taikai.transition_to!(:done)
    new_taikai = Taikai.create_from_2in1(@taikai.id, users(:jean_bon), "part2", "partie 2", 8)

    assert_equal :not_enough_non_mixed_teams_html, new_taikai.errors.details[:base].first[:error]
  end

  test "can create part two" do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    @taikai.transition_to!(:registration)
    @taikai.transition_to!(:marking)
    generate_taikai_results(@taikai)
    @taikai.transition_to!(:tie_break)
    @taikai.transition_to!(:done)
    new_taikai = Taikai.create_from_2in1(@taikai.id, users(:jean_bon), "part2", "partie 2", 8)

    assert new_taikai.errors.empty?
  end
end
