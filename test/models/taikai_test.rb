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

      assert_empty @taikai.errors
      assert_not_nil @taikai.id
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
      assert @taikai.in_state? :registration

      @taikai.participating_dojos.each(&:draw)
      @taikai.transition_to!(:marking)
      assert @taikai.in_state? :marking

      TestDataService.finalize_scores(@taikai)
      @taikai.transition_to!(:tie_break)
      assert @taikai.in_state? :tie_break

      @taikai.transition_to!(:done)
      assert @taikai.in_state? :done
    end
  end

  test "cannot change once done" do
    @taikai.form = :'2in1'
    transition_taikai_to(@taikai, :done)

    assert_raises ActiveRecord::RecordInvalid do
      @taikai.update!(shortname: "newshortname")
    end
  end

  test "cannot create part two without enough teams" do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :registration)

    @taikai.teams.last.destroy!

    transition_taikai_to(@taikai, :done)
    new_taikai = Taikai.create_from_2in1(@taikai.id, users(:jean_bon), "part2", "partie 2", 8)

    assert_equal :not_enough_teams, new_taikai.errors.details[:base].first[:error]
  end

  test "cannot create part two without enough non-mixed teams" do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :registration)
    @taikai.teams.each { |team| team.update(mixed: true) }
    transition_taikai_to(@taikai, :done)
    new_taikai = Taikai.create_from_2in1(@taikai.id, users(:jean_bon), "part2", "partie 2", 8)

    assert_equal :not_enough_non_mixed_teams_html, new_taikai.errors.details[:base].first[:error]
  end

  test "can create part two" do
    @taikai = taikais(:'2in1_dist_12_kinteki')
    @taikai.current_user = users(:jean_bon)
    transition_taikai_to(@taikai, :done)

    new_taikai = Taikai.create_from_2in1(@taikai.id, users(:jean_bon), "part2", "partie 2", 8)

    assert new_taikai.errors.empty?
  end
end
