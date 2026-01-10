require "application_system_test_case"
require "taikais_test_helpers"

class Taikais2in1Test < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    @taikai = taikais(:'2in1_dist_12_kinteki')
  end

  test "creating editing participating dojo" do
    sign_in_as users(:jean_bon)
    go_to_taikai :'2in1_dist_12_kinteki'

    click_link "Modifier"
    wait_for_turbo

    assert_selector "p.card-header-title", text: "Modification du Taikai", wait: 5

    within find("div.card", text: "Clubs hôtes") do
      within find("tr", text: "Participating Dojo1 2in1 Dist 12 Kinteki") do
        click_link "Modifier"
      end
    end
    wait_for_turbo

    assert_selector "p.card-header-title", text: "Modifier un club hôte", wait: 5
    assert_selector "p.card-header-title", text: "Importer la liste des participant"
  end
end
