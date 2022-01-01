require "test_helper"

class Participating_dojosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
    @participating_dojo = participating_dojos(:participating_dojo_1_taikai_1)
  end

  test "should get new" do
    get new_taikai_participating_dojo_url @taikai
    assert_response :success
  end

  test 'should post create' do
    assert_difference '@taikai.participating_dojos.count' do
      post taikai_participating_dojos_url @taikai, params: {
        participating_dojo: {
          taikai_id: @taikai.id,
          dojo_id: dojos(:dojo_jp).id,
          display_name: "Customized dojo name",
        }
      }
    end
    assert_redirected_to edit_taikai_url @taikai
  end

  test "should get edit" do
    get edit_taikai_participating_dojo_url @taikai, @participating_dojo
    assert_response :success
  end

  test "should patch update" do
    patch taikai_participating_dojo_url @taikai, @participating_dojo, params: { participating_dojo: @participating_dojo.attributes }
    assert_redirected_to edit_taikai_url @taikai
  end

  test "should get destroy" do
    delete taikai_participating_dojo_url @taikai, @participating_dojo
    assert_redirected_to edit_taikai_url @taikai
  end
end
