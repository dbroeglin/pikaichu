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
    test "#{form} #{distributed ? :distributed : :local} #{total_num_arrows} #{scoring} validates" do
      @taikai.scoring = scoring
      @taikai.distributed = distributed
      @taikai.form = form
      @taikai.total_num_arrows = total_num_arrows
      @taikai.save!
    end if distributed
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
end
