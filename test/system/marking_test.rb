require 'application_system_test_case'
require 'taikais_test_helpers'

class MarkingTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  Taikai.all.each do |taikai|
    test "visiting '#{taikai.shortname}' marking sheet" do
      go_to_taikais

      find("td", text: taikai.shortname).ancestor("tr").click_on("Feuille de marque")

      assert_selector "h1.title", text: "Feuille de marque"
      assert_selector "h1.title", text: taikai.shortname

      click_on "Retour au Taikai"

      assert_selector "p.title.is-4", text: taikai.name
    end
  end
end
