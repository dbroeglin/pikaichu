require 'application_system_test_case'

class UsersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit root_url

    assert_selector "p.card-header-title", text: "Log in"

    fill_in "Email", with: "jean.bon@example.org"
    fill_in "Password", with: "password"

    click_on "Log in"

    assert_selector "p.title", text: "Taikais"
    assert_selector "p.title", text: "Dojos"

    click_on "Manage Taikais"

    click_on "taikai"
    assert_selector "p.title", text: "Fail"
  end
end
