require 'application_system_test_case'
require 'taikais_test_helpers'

class LeaderboardTest < ApplicationSystemTestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  teardown do
    # Hack to avoid starting tests with a session from previous tests
    visit destroy_user_session_url
  end

  TAIKAI_DATA.each do |data|
    taikai = find_test_taikai(*data)

    test "visiting #{taikai.shortname} leaderboard" do
      taikai.current_user = users(:jean_bon)
      taikai.transition_to! :registration
      taikai.transition_to! :marking
      go_to_taikais

      find("a", exact_text: taikai.name).ancestor("tr").click_on("Tableau des résultats")

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Retour au Taikai"

      assert_taikai_title taikai.name
    end
  end

  TAIKAI_DATA.reject { |data| data[0] == 'match' }.each do |data|
    taikai = find_test_taikai(*data)

    test "visiting #{taikai.shortname} public leaderboard" do
      taikai.current_user = users(:jean_bon)
      taikai.transition_to! :registration
      taikai.transition_to! :marking
      go_to_taikais

      find("a", exact_text: taikai.name).ancestor("tr").click_on("Tableau des résultats")

      assert_selector "h1.title", text: "Tableau des résultats intermédiaires"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Résultats publics"

      assert_selector "h1.title", text: "Tableau des résultats - #{taikai.shortname}"

      click_on "Afficher les résultats en équipe" if taikai.form_2in1?
    end
  end

  TAIKAI_DATA.select { |data| data[0] == 'match' }.each do |data|
    taikai = find_test_taikai(*data)

    test "visiting #{taikai.shortname} public leaderboard" do
      skip "Public leaderboard for matches not implemented yet"
    end
  end
end
