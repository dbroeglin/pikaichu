require 'application_system_test_case'
require 'taikais_test_helpers'

class LeaderboardTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  Taikai.all.each do |taikai|
    test "visiting #{taikai.shortname} leaderboard" do
      taikai.transition_to! :registration
      taikai.transition_to! :marking
      go_to_taikais

      find("a", exact_text: taikai.shortname).ancestor("tr").click_on("Tableau des résultats")

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Retour au Taikai"

      assert_selector "p.title.is-4", text: taikai.name
    end
  end

  Taikai.where("form <> 'matches'").each do |taikai|
    test "visiting #{taikai.shortname} public leaderboard" do
      taikai.transition_to! :registration
      taikai.transition_to! :marking
      go_to_taikais

      find("a", exact_text: taikai.shortname).ancestor("tr").click_on("Tableau des résultats")

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Résultats publics"

      assert_selector "h1.title", text: "Tableau des résultats - #{taikai.shortname}"

      if taikai.form_2in1?
        click_on "Afficher les résultats en équipe"
      end
    end
  end

  Taikai.where("form = 'matches'").each do |taikai|
    test "visiting #{taikai.shortname} public leaderboard" do
      skip "Public leaderboard for matches not implemented yet"
    end
  end
end
