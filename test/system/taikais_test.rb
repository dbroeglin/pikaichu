require "application_system_test_case"
require "taikais_test_helpers"

class TaikaisTest < ApplicationSystemTestCase
  include TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  test "visiting taikais" do
    click_link "Gérer les Taikai"
    wait_for_turbo

    assert_selector "h1.title", text: "Liste des Taikai", wait: 5
  end

  test "visiting individual_12" do
    taikai = taikais(:individual_dist_12_kinteki)

    go_to_taikais

    assert_selector "h1.title", text: "Liste des Taikai"

    click_link taikai.shortname.titleize
    wait_for_turbo

    assert_taikai_title taikai.name
  end

  test "taikai state navigation uses POST buttons" do
    taikai = taikais(:individual_dist_12_kinteki)

    go_to_taikais

    click_link taikai.shortname.titleize
    wait_for_turbo

    next_state_path = transition_to_taikai_path(taikai, state: :registration)
    next_state_form = find("form[action='#{next_state_path}']")
    assert_equal "post", next_state_form[:method]

    accept_confirm do
      next_state_form.find("button").click
    end
    wait_for_turbo

    assert taikai.reload.in_state?(:registration)

    previous_state_path = transition_to_taikai_path(taikai, state: :new)
    previous_state_form = find("form[action='#{previous_state_path}']")
    assert_equal "post", previous_state_form[:method]

    accept_confirm do
      previous_state_form.find("button").click
    end
    wait_for_turbo

    assert taikai.reload.in_state?(:new)
  end

  TAIKAI_DATA.each do |form, distributed, total_num_arrows, scoring|
    test "creating a #{form} #{distributed ? :distributed : :local} #{total_num_arrows} arrows #{scoring} taikai" do
      shortname = "new-#{taikai_shortname form, distributed, total_num_arrows, scoring}"

      go_to_taikais

      click_link "Ajouter"
      wait_for_turbo

      assert_selector "p.title", text: "Ajouter un Taikai", wait: 5

      form_label = {
        individual: "Individuel",
        team: "En équipe",
        '2in1': "2 en 1",
        matches: "Matchs"
      }[form]
      scoring_label = scoring.to_s.capitalize

      fill_in_taikai shortname, form_label, distributed, total_num_arrows, scoring_label
      uncheck "À distance" unless distributed

      click_button "Sauvegarder"
      wait_for_turbo

      assert_selector "h1.title", text: "Liste des Taikai", wait: 5

      go_to_taikais # Display all taikais on one page
      assert_selector "td a", text: shortname.titleize, wait: 5

      click_link shortname.titleize
      wait_for_turbo

      assert_selector "p.subtitle.is-5 b", text: shortname, wait: 5
      assert_selector "p.subtitle.is-5", text: form_label
      assert_selector "p.subtitle.is-5", text: (distributed ? "À distance" : "Local")
      assert_selector "p.subtitle.is-5", text: "#{total_num_arrows} flèches"
      assert_selector "p.subtitle.is-5", text: scoring_label

      within find("td", text: "Administrateur") do
        assert_sibling "td", text: "Jean Bon"
      end
    end
  end

  private

  def fill_in_taikai(shortname, form_label, distributed, total_num_arrows, scoring_label)
    fill_in "Nom court", with: shortname
    fill_in "Nom entier", with: shortname.titleize
    fill_in "Date de début", with: "05/02/2002"
    fill_in "Date de fin", with: "06/02/2002"

    select(form_label, from: "Forme")
    select(scoring_label, from: "Type de score")

    fill_in "Nb total de flèches", with: total_num_arrows

    check "À distance" if distributed
  end

  # Helper method for finding sibling elements
  def assert_sibling(selector, text:)
    parent = page.find(:xpath, "..")
    assert parent.has_selector?(selector, text: text), "Expected to find sibling #{selector} with text '#{text}'"
  end
end
