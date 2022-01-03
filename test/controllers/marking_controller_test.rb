require "test_helper"

class MarkingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
    @participant = participants(:participant_1_participating_dojo_1_taikai_1)
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
