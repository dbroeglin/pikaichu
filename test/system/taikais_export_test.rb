require 'application_system_test_case'
require 'taikais_test_helpers'

class TaikaisExportTest < ApplicationSystemTestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers
  include DownloadHelpers

  setup do
    sign_in_as users(:jean_bon)

    ### Allow file downloads in Google Chrome when headless!!!
    ### https://bugs.chromium.org/p/chromium/issues/detail?id=696481#c89
    bridge = Capybara.current_session.driver.browser.send(:bridge)

    path = '/session/:session_id/chromium/send_command'
    path[':session_id'] = bridge.session_id

    bridge.http.call(:post, path,
                     cmd: 'Page.setDownloadBehavior',
                     params: {
                       behavior: 'allow',
                       downloadPath: DownloadHelpers::PATH
                     })
  end

  teardown do
    clear_downloads
  end

  TAIKAI_DATA.each do |data|
    taikai = find_test_taikai(*data)

    next unless taikai.form_matches?

    # TODO: refactor test data generation
    taikai_admin = StaffRole.find_by!(code: 'taikai_admin')
    roles = [
      StaffRole.find_by!(code: 'chairman'),
      StaffRole.find_by!(code: 'shajo_referee'),
      StaffRole.find_by!(code: 'target_referee'),
    ]

    test "Exporting #{taikai.shortname} XLSX" do
      taikai.current_user = users(:jean_bon)
      taikai.transition_to! :registration
      if taikai.staffs.empty?
        taikai.staffs.create!(firstname: "a", lastname: "b", role: taikai_admin, user: users(:jean_bon))
      end
      roles.each do |role|
        taikai.staffs.create!(firstname: "a", lastname: "b", role: role)
      end
      taikai.transition_to! :marking
      TestDataService.finalize_scores(taikai)

      taikai.transition_to! :tie_break
      taikai.transition_to! :done
      go_to_taikais

      find("a", exact_text: taikai.name).ancestor("tr").click_on("Export Excel")

      assert_match(%r{.*/Taikai - #{taikai.shortname}\.xlsx$}, last_download)
    end
  end

  teardown do
    # Hack to avoid starting tests with a session from previous tests
    visit destroy_user_session_url
  end
end
