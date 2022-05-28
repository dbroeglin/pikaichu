require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:individual_dist_12)
    @participating_dojo = participating_dojos(:participating_dojo1_individual_12)
    @staff = staffs(:staff1_individual_12)
  end

  test "should search dojos" do
    get taikai_participating_dojo_available_dojos_url @taikai, @participating_dojo
    assert_response :success
  end

  test "should search users" do
    get taikai_staff_available_users_url @taikai, @staff
    assert_response :success
  end
end
