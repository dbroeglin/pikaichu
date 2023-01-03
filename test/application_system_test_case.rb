require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  DRIVER = if ENV["DRIVER"]
    ENV["DRIVER"].to_sym
  else
    :headless_chrome
  end
  driven_by :selenium, using: DRIVER, screen_size: [1400, 1400]

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
