require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  test "user can sign up successfully" do
    visit new_registration_path

    fill_in "user_firstname", with: "John"
    fill_in "user_lastname", with: "Doe"
    fill_in "user_email_address", with: "john.doe@example.com"
    # Don't change locale, use default
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    click_button I18n.t("registrations.new.submit")

    assert_text I18n.t("registrations.account_created")
    assert_current_path root_path
  end

  test "user sees validation errors for invalid data" do
    visit new_registration_path

    # Try to submit with short password
    fill_in "user_firstname", with: "John"
    fill_in "user_lastname", with: "Doe"
    fill_in "user_email_address", with: "john.doe@example.com"
    fill_in "user_password", with: "short"
    fill_in "user_password_confirmation", with: "short"

    click_button I18n.t("registrations.new.submit")

    # Check for error message (could be in French or English depending on locale)
    assert_selector ".notification.is-danger"
  end

  test "user can navigate to sign in from sign up page" do
    visit new_registration_path

    click_link I18n.t("registrations.new.sign_in_link")

    assert_current_path new_session_path
  end

  test "user can navigate to sign up from sign in page" do
    visit new_session_path

    click_link I18n.t("sessions.new.sign_up_link")

    assert_current_path new_registration_path
  end

  test "sign up form displays in French when locale is fr" do
    I18n.with_locale(:fr) do
      visit new_registration_path

      assert_text I18n.t("registrations.new.title", locale: :fr)
      assert_text I18n.t("registrations.new.subtitle", locale: :fr)
    end
  end
end
