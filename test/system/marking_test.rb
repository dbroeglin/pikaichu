require 'application_system_test_case'
require 'taikais_test_helpers'

class MarkingTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    @current_user = sign_in_as users(:jean_bon)
  end

  Taikai.all.each do |taikai|
    test "visiting #{taikai.shortname} marking sheet" do
      taikai.current_user = users(:jean_bon)
      taikai.transition_to! :registration
      taikai.transition_to! :marking
      go_to_taikais

      find("td", exact_text: taikai.name).ancestor("tr").click_on("Feuille de marque")

      if taikai.form_matches?
        assert_selector "h1.title", text: "Tableau des matchs"
      else
        assert_selector "h1.title", text: "Feuille de marque"
      end
      assert_selector "h1.title", text: taikai.shortname

      click_on "Retour au Taikai"

      assert_selector "p.title.is-4", text: taikai.name
    end
  end
end
