require "test_helper"
require "download_helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Disable parallelization for system tests to avoid session conflicts
  parallelize(workers: 1)

  include FactoryBot::Syntax::Methods

  # Configure Capybara for Hotwire/Turbo compatibility
  Capybara.default_max_wait_time = 5
  Capybara.enable_aria_label = true

  # Register headless Chrome driver with proper configuration
  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new

    # Headless mode
    options.add_argument("--headless=new") # Use new headless mode
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1400,1400")

    # Performance optimizations
    options.add_argument("--disable-extensions")
    options.add_argument("--disable-background-networking")
    options.add_argument("--disable-background-timer-throttling")
    options.add_argument("--disable-backgrounding-occluded-windows")
    options.add_argument("--disable-renderer-backgrounding")

    # Download preferences
    options.add_preference(:download, {
      prompt_for_download: false,
      default_directory: DownloadHelpers::PATH.to_s
    })

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  # Register visible Chrome driver for debugging
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--window-size=1400,1400")
    options.add_preference(:download, {
      prompt_for_download: false,
      default_directory: DownloadHelpers::PATH.to_s
    })

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  # Use visible Chrome if CHROME_DEBUG is set, otherwise headless
  driven_by ENV["CHROME_DEBUG"] == "true" ? :chrome : :headless_chrome

  def sign_in_as(user)
    # Clear any existing session first
    Capybara.reset_sessions!

    visit root_url

    # Wait for page to fully load
    assert_selector "body"

    # If already logged in, log out first
    if has_selector?("a", text: "Déconnexion", wait: 1)
      click_link "Déconnexion"
      assert_selector "button", text: "Connexion"
    end

    # Perform login
    fill_in "Email", with: user.email
    fill_in "Mot de passe", with: "password"

    click_button "Connexion"

    # Wait for successful login - Turbo navigation
    assert_selector "p.title", text: "Taikai", wait: 5
    assert_selector "p.title", text: "Clubs"

    user
  end

  # Helper to wait for Turbo to finish navigating
  def wait_for_turbo(timeout: Capybara.default_max_wait_time)
    if has_css?(".turbo-progress-bar", visible: true, wait: 0.5)
      has_no_css?(".turbo-progress-bar", wait: timeout)
    end
  end

  # Helper to click and wait for navigation
  def click_and_wait(locator, **options)
    click_on locator, **options
    wait_for_turbo
  end

  # Setup downloads directory before each test
  def setup
    super
    FileUtils.mkdir_p(DownloadHelpers::PATH)
    clear_downloads if respond_to?(:clear_downloads)
  end

  # Clean up after each test
  def teardown
    # Clear downloads if module is included
    clear_downloads if respond_to?(:clear_downloads)

    # Reset Capybara session to prevent test interference
    Capybara.reset_sessions!

    super
  end
end
