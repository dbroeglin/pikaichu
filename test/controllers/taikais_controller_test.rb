require "test_helper"

class TaikaisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
  end

  test "should get index" do
    get taikais_url
    assert_response :success
  end

  test "should get edit" do
    get edit_taikai_url @taikai
    assert_response :success
  end

  test "should get new" do
    get new_taikai_url
    assert_response :success
  end

  test "should patch update" do
    patch taikai_url @taikai, params: { taikai: @taikai.attributes }
    assert_redirected_to taikais_url
  end

  test "should get destroy" do
    delete taikai_url @taikai
    assert_redirected_to taikais_url
  end
end
