require "application_system_test_case"
require "taikais_test_helpers"

class TaikaisExportTest < ApplicationSystemTestCase
  include TaikaisTestHelpers
  extend TaikaisTestHelpers
  include DownloadHelpers

  setup do
    sign_in_as users(:jean_bon)
    clear_downloads
  end

  teardown do
    clear_downloads
  end

  TAIKAI_DATA.each do |data|
    taikai = find_test_taikai(*data)

    next unless taikai.form_matches?

    # TODO: refactor test data generation
    taikai_admin = StaffRole.find_by!(code: "taikai_admin")
    roles = [
      StaffRole.find_by!(code: "chairman"),
      StaffRole.find_by!(code: "shajo_referee"),
      StaffRole.find_by!(code: "target_referee")
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

      within find("tr", text: taikai.name) do
        click_link "Export Excel"
      end

      # Wait for download to complete
      begin
        download_file = wait_for_download(taikai.shortname)
        assert_match(%r{.*/Taikai - #{taikai.shortname}\.xlsx$}, download_file)
      rescue Timeout::Error
        # If download fails, check if we got redirected to an error page
        assert false, "Download did not complete. Current downloads: #{downloads.inspect}"
      end
    end
  end

  private

  def wait_for_download(taikai_shortname, timeout: 15)
    Timeout.timeout(timeout) do
      loop do
        sleep 0.5

        # Check if .crdownload file exists (Chrome downloading)
        next if downloads.any? { |f| f.end_with?(".crdownload") }

        # Look for the expected file
        matching_download = downloads.find { |f| f.include?(taikai_shortname) && f.end_with?(".xlsx") }
        return matching_download if matching_download

        # If we have downloads but none match, might be an error
        if downloads.any? && !downloads.any? { |f| f.end_with?(".crdownload") }
          # Give it one more second in case file is being written
          sleep 1
          matching_download = downloads.find { |f| f.include?(taikai_shortname) && f.end_with?(".xlsx") }
          return matching_download if matching_download
        end
      end
    end
  end
end
