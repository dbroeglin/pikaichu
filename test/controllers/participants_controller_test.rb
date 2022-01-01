require "test_helper"

class ParticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
    @participating_dojo = participating_dojos(:participating_dojo_1_taikai_1)
    @participant = participants(:participant_1_participating_dojo_1_taikai_1)
  end

  test "should get edit" do
    get edit_taikai_participating_dojo_participant_url @taikai, @participating_dojo, @participant
    assert_response :success
  end

  test "should get new" do
    get new_taikai_participating_dojo_participant_url @taikai, @participating_dojo
    assert_response :success
  end

  test "should patch update" do
    patch taikai_participating_dojo_participant_url @taikai, @participating_dojo, @participant,
      params: { participant: @participant.attributes }
    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
  end

  test "should get destroy" do
    delete taikai_participating_dojo_participant_url @taikai, @participating_dojo, @participant
    assert_redirected_to edit_taikai_participating_dojo_url @taikai, @participating_dojo
  end
end
