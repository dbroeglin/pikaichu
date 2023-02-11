# rubocop:disable Naming/VariableNumber

require 'application_system_test_case'
require 'taikais_test_helpers'

class Taikais2in1Test < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    @taikai = taikais(:'2in1_12')
  end

  test "creating editing participating dojo" do
    sign_in_as users(:jean_bon)
    go_to_taikai :'2in1_12'

    click_on "Modifier"
    assert_selector "p.card-header-title", text: "Modification du Taikai"

    find("td", text: "Participating Dojo1 2in1 12").ancestor("tr").click_on "Modifier"

    assert_selector "p.card-header-title", text: "Modifier un club hôte"
    assert_selector "p.card-header-title", text: "Importer la liste des participant"
  end
end
