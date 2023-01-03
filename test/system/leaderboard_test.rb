require 'application_system_test_case'
require 'taikais_test_helpers'

class LeaderboardTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  Taikai.all.each do |taikai|
    test "visiting '#{taikai.shortname}' leaderboard" do
      go_to_taikais

      find("a", exact_text: taikai.shortname).ancestor("tr").click_on("Tableau des résultats")

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Retour au Taikai"

      assert_selector "p.title.is-4", text: taikai.name
    end
  end


  Taikai.where("form <> 'matches'").each do |taikai|
    test "visiting '#{taikai.shortname}' public leaderboard" do
      go_to_taikais

      find("a", exact_text: taikai.shortname).ancestor("tr").click_on("Tableau des résultats")

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Résultats publics"

      assert_selector "h1.title", text: "Tableau des résultats -"
    end
  end
end
