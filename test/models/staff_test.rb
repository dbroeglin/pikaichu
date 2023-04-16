require "test_helper"

class StaffTest < ActiveSupport::TestCase

  setup do
    @taikai = taikais(:'2in1_dist_12_enteki')
  end

  test "should not destroy last taikai admin" do
    assert_equal 1, @taikai.staffs.with_role(:taikai_admin).count
    assert_equal false, @taikai.staffs.first.destroy
  end

  test "should validate additional taikai admin" do
    assert_equal 1, @taikai.staffs.with_role(:taikai_admin).count
    assert_not_equal false, @taikai.staffs.create(
      firstname: 'Alex',
      lastname: 'Terieur',
      role: staff_roles(:taikai_admin),
    )
  end

  test "should not change role of last taikai admin" do
    assert_equal 1, @taikai.staffs.with_role(:taikai_admin).count
    staff = @taikai.staffs.first

    staff.role = staff_roles(:dojo_admin)
    assert_equal false, staff.save
    assert_not_empty staff.errors[:base]
    assert_equal :at_least_one_admin, staff.errors.where(:base).first.type
  end
end
