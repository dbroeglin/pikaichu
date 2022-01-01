require "test_helper"

class DojosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @dojo = dojos(:dojo_jp)
  end

  test "should get index" do
    get dojos_url
    assert_response :success
  end

  test "should get edit" do
    get edit_dojo_url @dojo
    assert_response :success
  end

  test "should get new" do
    get new_dojo_url
    assert_response :success
  end

  test "should patch update" do
    patch dojo_url @dojo, params: { dojo: @dojo.attributes }
    assert_redirected_to dojos_url
  end

  test "should get destroy" do
    delete dojo_url dojos(:dojo_to_delete)
    assert_redirected_to dojos_url
  end
end
