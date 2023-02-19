# rubocop:disable Naming/VariableNumber

require 'application_system_test_case'
require 'taikais_test_helpers'

class TaikaisTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  test "visiting taikais" do
    taikai = taikais(:individual_12)

    click_on "Gérer les Taikai"

    assert_selector "h1.title", text: "Liste des Taikai"
  end

  test "visiting individual_12" do
    taikai = taikais(:individual_12)

    go_to_taikais

    assert_selector "h1.title", text: "Liste des Taikai"

    click_on taikai.shortname.titleize

    assert_selector "p.title.is-4", text: "#{taikai.name} (#{taikai.shortname})"
  end

  [
    [:individual, false, 12],
    [:team,       false, 12],
    [:'2in1',     false, 12],
    [:individual, false, 20],
    [:team,       false, 20],
    [:'2in1',     false, 20],
    [:individual, true,  12],
    [:team,       true,  12],
    [:'2in1',     true,  12],
    [:individual, true,  20],
    [:team,       true,  20],
    [:'2in1',     true,  20],
  ].each do |form, distributed, total_num_arrows|
    test "creating a #{form} #{distributed} #{total_num_arrows} arrows taikai" do
      shortname = "#{form}-#{distributed}-#{total_num_arrows}-taikai"

      go_to_taikais

      click_on "Ajouter"

      assert_selector "p.title", text: "Ajouter un Taikai"

      form_label = { individual: 'Individuel', team: 'En équipe', '2in1': '2 en 1' }[form]
      fill_in_taikai shortname, form_label, distributed, total_num_arrows
      uncheck "À distance" unless distributed
      click_on "Sauvegarder"

      assert_selector "h1.title", text: "Liste des Taikai"

      go_to_taikais # Display all taikais on one page
      assert_selector "td a", text: shortname.titleize

      click_on shortname.titleize

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
