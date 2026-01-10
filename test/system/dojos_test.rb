require "application_system_test_case"

class DojosTest < ApplicationSystemTestCase
  test "visiting the dojos" do
    sign_in_as users(:jean_bon)

    click_on "Gérer les Club"

    assert_selector "h1.title", text: "Liste des Clubs"
  end
end
