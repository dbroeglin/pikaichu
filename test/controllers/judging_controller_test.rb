require "test_helper"

class JudgingControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
    @participant = participants(:participant_1_participating_dojo_1_taikai_1)
  end

  test "should get show" do
    get show_judging_url @taikai
    assert_response :success
  end

  test "should post update" do
    post update_judging_url @taikai, @participant, params: { status: 'hit' }
    assert_redirected_to show_judging_url @taikai
  end
end
