require 'application_system_test_case'
require 'taikais_test_helpers'

class Taikais2in1Test < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    @taikai = taikais(:'2in1_dist_12_kinteki')
  end

  test "creating editing participating dojo" do
    sign_in_as users(:jean_bon)
    go_to_taikai :'2in1_dist_12_kinteki'

    click_on "Modifier"
    assert_selector "p.card-header-title", text: "Modification du Taikai"

    find("p.card-header-title", text: "Clubs hôtes")
      .ancestor("div.card")
      .find("td", text: "Participating Dojo1 2in1 Dist 12 Kinteki")
      .ancestor("tr")
      .click_on "Modifier"

    assert_selector "p.card-header-title", text: "Modifier un club hôte"
    assert_selector "p.card-header-title", text: "Importer la liste des participant"
  end
end
