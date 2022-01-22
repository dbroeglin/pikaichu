require 'application_system_test_case'

class TaikaisTest < ApplicationSystemTestCase
  test "visiting the taikai-1" do
    sign_in_as users(:jean_bon)

    click_on "Gérer les Taikai"

    assert_selector "h1.title", text: "Liste des Taikais"

    click_on "taikai-1"

    assert_selector "p.title.is-4", text: "Taikai 1 (taikai-1)"
  end

  test "creating a taikai" do
    sign_in_as users(:jean_bon)
    shortname = "awesome-taikai"

    click_on "Gérer les Taikai"

    assert_selector "h1.title", text: "Liste des Taikais"

    click_on "Ajouter"

    assert_selector "p.title", text: "Ajouter un Taikai"

    fill_in "Nom court", with: shortname
    fill_in "Nom entier", with: "Awesome Taikai"
    fill_in "Date de début", with: "05/02/2002"
    fill_in "Date de fin", with: "06/02/2002"

    click_on "Sauvegarder"

    assert_selector "td a", text: shortname

    click_on shortname

    assert_selector "p.title.is-4", text: "Awesome Taikai (#{shortname})"

    find("td", text: "Administrateur").assert_sibling("td", text: "Jean Bon")
  end
end
