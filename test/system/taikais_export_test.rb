# rubocop:disable Naming/VariableNumber

require 'application_system_test_case'
require 'taikais_test_helpers'

class TaikaisExportTest < ApplicationSystemTestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers

  setup do
    sign_in_as users(:jean_bon)
  end

  TAIKAI_DATA.each do |data|
    taikai = Taikai.find_by!(shortname: taikai_shortname(*data))

    test "Exporting #{taikai.shortname} XLSX" do
      taikai.current_user = users(:jean_bon)
      taikai.transition_to! :registration
      taikai.transition_to! :marking
      taikai.participants.map {|participant| participant.score.results }.flatten
      .each { |r|
        r.status = ['hit', 'miss'].sample
        r.final = true
        r.save
      }
      taikai.transition_to! :tie_break
      taikai.transition_to! :done
      go_to_taikais

      find("a", exact_text: taikai.name).ancestor("tr").click_on("Export Excel")

      expect(page.response_headers["Content-Disposition"]).to match "Receipt-#{receipt.id}.pdf"
    end
  end

end
