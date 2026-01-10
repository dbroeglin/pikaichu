require "test_helper"

class StaffsFlowTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @taikai = taikais(:'2in1_dist_12_enteki')
    @test_staff = @taikai.staffs.first

    @taikai.current_user = users(:jean_bon)
    @taikai.transition_to! :registration
  end

  test "should get new" do
    # catches Statesman guard issue
    get new_taikai_staff_url @taikai

    assert_response :success

    assert_select "p.title", "Ajouter un staff"
  end
end
