require "test_helper"

class TaikaiEventTest < ActiveSupport::TestCase
  test "state transitions persist the acting user and state change" do
    taikai = taikais(:'2in1_dist_12_enteki')
    user = users(:jean_bon)
    taikai.current_user = user

    assert_difference "TaikaiEvent.count", 1 do
      taikai.transition_to!(:registration)
    end

    event = TaikaiEvent.order(:id).last
    assert_equal taikai, event.taikai
    assert_equal user, event.user
    assert_equal "state_transition", event.category
    assert_equal "new", event.data["from"]
    assert_equal "registration", event.data["to"]
    assert_equal user.id, event.data.dig("user", "id")
    assert_equal taikai.id, event.data.dig("taikai", "id")
  end
end
