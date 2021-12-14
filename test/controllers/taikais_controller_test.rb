require "test_helper"

class TaikaisControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get taikais_index_url
    assert_response :success
  end

  test "should get show" do
    get taikais_show_url
    assert_response :success
  end

  test "should get edit" do
    get taikais_edit_url
    assert_response :success
  end

  test "should get new" do
    get taikais_new_url
    assert_response :success
  end

  test "should get update" do
    get taikais_update_url
    assert_response :success
  end

  test "should get delete" do
    get taikais_delete_url
    assert_response :success
  end
end
