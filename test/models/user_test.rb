require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = User.new(firstname: "Test", lastname: "User", password: "password123")
    assert_not user.save, "Saved the user without an email"
  end
end
