require "test_helper"
require "download_helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include FactoryBot::Syntax::Methods

  driver = if ENV['CHROME_DEBUG'] == 'true'
             Capybara.register_driver :chrome do |app|
               Capybara::Selenium::Driver.new(app, browser: :chrome)
             end
             :chrome
           else
             Capybara.register_driver :test do |app|
               browser_options = ::Selenium::WebDriver::Chrome::Options.new
               browser_options.add_argument('headless')
               browser_options.add_argument('disable-gpu')
               browser_options.add_argument('window-size=1400,1200')

               browser_options.add_preference(:download,
                                              "directory_upgrade" => true,
                                              "prompt_for_download" => false,
                                              "default_directory" => DownloadHelpers::PATH)
               browser_options.add_preference(
                 "browser",
                 "set_download_behavior" => { "behavior" => 'allow' }
               )
               browser_options.add_preference('download.default_directory', DownloadHelpers::PATH)

               Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options,
                                                   timeout: 30).tap do |drv|
                 # drv.download_path = DownloadHelpers::PATH
               end
             end
             :test
           end

  # Selenium::WebDriver.logger.level = :debug
  # Selenium::WebDriver.logger.output = $stderr

  driven_by driver

  def sign_in_as(user)
    visit root_url

    assert_selector 'button', text: "Connexion"

    fill_in "Email", with: user.email
    fill_in "Mot de passe", with: 'password'

    find_button("Connexion").click

    assert_selector "p.title", text: "Taikai"
    assert_selector "p.title", text: "Clubs"
  end
end
