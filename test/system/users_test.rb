require 'application_system_test_case'

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

    find_button("Connexion").click

    assert_selector "p.title", text: "Taikais"
    assert_selector "p.title", text: "Clubs"

    click_on "Déconnexion"
  end
end
