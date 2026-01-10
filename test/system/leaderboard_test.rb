require "application_system_test_case"
require "taikais_test_helpers"

class LeaderboardTest < ApplicationSystemTestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  TAIKAI_DATA.each do |data|
    taikai = find_test_taikai(*data)

    test "visiting #{taikai.shortname} leaderboard" do
      taikai.current_user = users(:jean_bon)
      transition_taikai_to(taikai, :marking)
      go_to_taikais

      within find("tr", text: taikai.name) do
        click_link "Tableau des résultats"
      end
      wait_for_turbo

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires", wait: 5
      assert_selector "h1.title", text: taikai.shortname, wait: 5

      click_link "Retour au Taikai"
      wait_for_turbo

      assert_taikai_title taikai.name
    end
  end

  TAIKAI_DATA.reject { |data| data[0] == "match" }.each do |data|
    taikai = find_test_taikai(*data)

    test "visiting #{taikai.shortname} public leaderboard" do
      taikai.current_user = users(:jean_bon)
      transition_taikai_to(taikai, :marking)
      go_to_taikais

      within find("tr", text: taikai.name) do
        click_link "Tableau des résultats"
      end
      wait_for_turbo

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires", wait: 5
      assert_selector "h1.title", text: taikai.shortname, wait: 5

      click_link "Résultats publics"
      wait_for_turbo

      assert_selector "h1.title", text: "Tableau des résultats - #{taikai.shortname}", wait: 5

      click_link "Afficher les résultats en équipe", wait: 2 if taikai.form_2in1? && has_link?("Afficher les résultats en équipe", wait: 1)
    end
  end

  TAIKAI_DATA.select { |data| data[0] == "match" }.each do |data|
    taikai = find_test_taikai(*data)

    test "visiting #{taikai.shortname} public leaderboard" do
      skip "Public leaderboard for matches not implemented yet"
    end
  end
end
