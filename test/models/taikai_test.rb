require "test_helper"

class TaikaiTest < ActiveSupport::TestCase
  setup do
    @taikai = Taikai.new(
      shortname: 'test-taikai',
      name: 'Test Taikai',
      start_date: Date.today,
      end_date: Date.today,
      current_user: users(:vince)
    )
  end

  [
    [:kinteki, :individual, 12],
    [:kinteki, :team,       12],
    [:kinteki, :'2in1',     12],
    [:kinteki, :individual, 20],
    [:kinteki, :team,       20],
    [:kinteki, :'2in1',     20],
    [:kinteki, :matches,     4],
    [:enteki,  :individual, 12],
    [:enteki,  :team,       12],
    [:enteki,  :'2in1',     12],
    [:enteki,  :matches,     4],
    [:enteki,  :individual, 13],
    [:enteki,  :individual, 22],
  ].each do |scoring, form, total_num_arrows|
    test "#{scoring} #{form} #{total_num_arrows} validates" do
      @taikai.scoring = scoring
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
end
