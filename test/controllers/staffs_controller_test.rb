require 'test_helper'

class StaffsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:taikai_1)
    @staff = staffs(:staff_1_taikai_1)
  end

  test 'should get new' do
    get new_taikai_staff_url @taikai
    assert_response :success
  end

  test 'should post create' do
    assert_difference '@taikai.staffs.count' do
      post taikai_staffs_url @taikai, params: { staff: {
          firstname: "Dan",
          lastname: "Brown",
          taikai_id: @taikai.id,
          role_id: staff_roles(:chairman),
          participating_dojo_id: participating_dojos(:participating_dojo_1_taikai_1)
        }
      }
    end
    assert_redirected_to edit_taikai_url @taikai
  end

  test 'should get edit' do
    get edit_taikai_staff_url @taikai, @staff
    assert_response :success
  end

 test 'should patch update' do
    patch taikai_staff_url @taikai, @staff, params: { staff: @staff.attributes }
    assert_redirected_to edit_taikai_url @taikai
  end

  test 'should get destroy' do
    delete taikai_staff_url @taikai, @staff
    assert_redirected_to edit_taikai_url @taikai
  end
end
