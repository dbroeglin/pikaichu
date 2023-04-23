require 'test_helper'

class StaffsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:'2in1_dist_12_enteki')
    @test_staff = @taikai.staffs.first
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
        user_id: users(:pat_ronat).id,
        role_id: staff_roles(:taikai_admin),
        participating_dojo_id: @taikai.participating_dojos.first
      } }
    end
    assert_redirected_to edit_taikai_url @taikai
  end

  test 'should get edit' do
    get edit_taikai_staff_url @taikai, @test_staff
    assert_response :success
  end

  test 'should patch update' do
    patch taikai_staff_url @taikai, @test_staff, params: { staff: @test_staff.attributes }
    assert_redirected_to edit_taikai_url @taikai
  end

  test 'should get destroy' do
    delete taikai_staff_url @taikai, @test_staff
    assert_redirected_to edit_taikai_url @taikai
  end
end
