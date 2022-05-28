require "test_helper"

class MarkingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_12)
    @participant = participants(:participant1_participating_dojo1_individual_12)
    @participant.create_empty_results
  end

  test "should get show" do
    get show_marking_url @taikai
    assert_response :success
  end

  test "should post update" do
    post update_marking_url @taikai, @participant, params: { status: 'hit' }
    assert_redirected_to show_marking_url @taikai
  end
end
