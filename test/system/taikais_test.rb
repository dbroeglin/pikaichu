require 'application_system_test_case'
require 'taikais_test_helpers'

class TaikaisTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  test 'visiting taikais' do
    click_on 'Gérer les Taikai'

    assert_selector 'h1.title', text: 'Liste des Taikai'
  end

  test 'visiting individual_12' do
    taikai = taikais(:individual_dist_12_kinteki)

    go_to_taikais

    assert_selector 'h1.title', text: 'Liste des Taikai'

    click_on taikai.shortname.titleize

    assert_taikai_title taikai.name
  end

  TAIKAI_DATA.each do |form, distributed, total_num_arrows, scoring|
    test "creating a #{form} #{distributed ? :distributed : :local} #{total_num_arrows} arrows #{scoring} taikai" do
      shortname = "new-#{taikai_shortname form, distributed, total_num_arrows, scoring}"

      go_to_taikais

      click_on 'Ajouter'

      assert_selector 'p.title', text: 'Ajouter un Taikai'

      form_label = {
        individual: 'Individuel',
        team: 'En équipe',
        '2in1': '2 en 1',
        matches: 'Matchs'
      }[form]
      scoring_label = scoring.to_s.capitalize

      fill_in_taikai shortname, form_label, distributed, total_num_arrows, scoring_label
      uncheck 'À distance' unless distributed
      click_on 'Sauvegarder'

      assert_selector 'h1.title', text: 'Liste des Taikai'

      go_to_taikais # Display all taikais on one page
      assert_selector 'td a', text: shortname.titleize

      click_on shortname.titleize

      assert_selector 'p.subtitle.is-5 b', text: shortname
      assert_selector 'p.subtitle.is-5', text: form_label
      assert_selector 'p.subtitle.is-5', text: (distributed ? 'À distance' : 'Local')
      assert_selector 'p.subtitle.is-5', text: "#{total_num_arrows} flèches"
      assert_selector 'p.subtitle.is-5', text: scoring_label

      find('td', text: 'Administrateur').assert_sibling('td', text: 'Jean Bon')
    end
  end

  private

  def fill_in_taikai(shortname, form_label, distributed, total_num_arrows, scoring_label)
    fill_in 'Nom court', with: shortname
    fill_in 'Nom entier', with: shortname.titleize
    fill_in 'Date de début', with: '05/02/2002'
    fill_in 'Date de fin', with: '06/02/2002'

    select(form_label, from: 'Forme')
    select(scoring_label, from: 'Type de score')

    fill_in 'Nb total de flèches', with: total_num_arrows

    check 'À distance' if distributed
  end
end
