require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @dojo = dojos(:dojo_fr)
  end

  test "should get index" do
    get root_url
    assert_response :success
  end
end
