require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:jean_bon)
  end

  test "disconnecting" do
    skip "Devise does not send a redirect 303 which causes a DELETE redirect..."

    visit root_url

    assert_selector "p.card-header-title", text: "Connexion"

    fill_in "Email",        with: @user.email
    fill_in "Mot de passe", with: "password"

    click_button "Connexion"
    wait_for_turbo

    assert_selector "p.title", text: "Taikai", wait: 5
    assert_selector "p.title", text: "Clubs"

    click_link "Déconnexion"
    wait_for_turbo
  end
end
