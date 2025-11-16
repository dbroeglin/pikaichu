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
      transition_taikai_to(taikai, :marking)
      go_to_taikais

      # Click and wait for navigation
      within find("tr", text: taikai.name) do
        click_link "Feuille de marque"
      end
      
      # Wait for Turbo navigation to complete
      wait_for_turbo

      # The title includes the shortname, so just check for the combined text
      if taikai.form_matches?
        assert_selector "h1.title", text: "Tableau des matchs", wait: 5
      else
        assert_selector "h1.title", text: "Feuille de marque", wait: 5
      end
      assert_selector "h1.title", text: taikai.shortname, wait: 5

      click_link "Retour au Taikai"
      wait_for_turbo

      assert_taikai_title taikai.name
    end
  end
end
