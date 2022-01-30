require 'application_system_test_case'
require 'taikais_test_helpers'

class TaikaisTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  test "visiting taikai-1" do
    shortname = taikais('individual_12').shortname

    click_on "Gérer les Taikai"

    assert_selector "h1.title", text: "Liste des Taikai"

    click_on shortname

    assert_selector "p.title.is-4", text: "Taikai 1 (#{shortname})"
  end


  [
    [:individual, :false, 12],
    [:team,       :false, 12],
    [:'2in1',     :false, 12],
    [:individual, :false, 20],
    [:team,       :false, 20],
    [:'2in1',     :false, 20],
    [:individual, :true,  12],
    [:team,       :true,  12],
    [:'2in1',     :true,  12],
    [:individual, :true,  20],
    [:team,       :true,  20],
    [:'2in1',     :true,  20],
  ].each do |form, distributed, total_num_arrows|

    test "creating an #{form}/#{distributed} #{total_num_arrows} arrows taikai" do
      shortname = "#{form}-#{distributed}-#{total_num_arrows}-taikai"

      go_to_taikais

      click_on "Ajouter"

      assert_selector "p.title", text: "Ajouter un Taikai"

      form_label = { individual: 'Individuel', team: 'En équipe', '2in1': '2 en 1' }[form]
      fill_in_taikai shortname, form_label, distributed, total_num_arrows
      click_on "Sauvegarder"

      assert_selector "h1.title", text: "Liste des Taikai"
      assert_selector "td a", text: shortname

      click_on shortname

      assert_selector "p.title.is-4", text: "#{shortname.titleize} (#{shortname})"
      assert_selector "p.subtitle.is-6", text: form_label
      assert_selector "p.subtitle.is-6", text: (distributed ? "À distance" : "Local")
      assert_selector "p.subtitle.is-6", text: "#{total_num_arrows} flèches"

      find("td", text: "Administrateur").assert_sibling("td", text: "Jean Bon")
    end
  end

  private

  def fill_in_taikai(shortname, form_label, distributed, total_num_arrows)
    fill_in "Nom court", with: shortname
    fill_in "Nom entier", with: shortname.titleize
    fill_in "Date de début", with: "05/02/2002"
    fill_in "Date de fin", with: "06/02/2002"

    select(form_label, from: 'Forme')

    fill_in "Nb total de flèches", with: total_num_arrows

    check "À distance" if distributed
  end
end
