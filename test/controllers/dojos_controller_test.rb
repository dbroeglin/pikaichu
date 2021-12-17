require "test_helper"

class DojosControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get dojos_index_url
    assert_response :success
  end

  test "should get edit" do
    get dojos_edit_url
    assert_response :success
  end

  test "should get new" do
    get dojos_new_url
    assert_response :success
  end

  test "should get update" do
    get dojos_update_url
    assert_response :success
  end

  test "should get destroy" do
    get dojos_destroy_url
    assert_response :success
  end
end
