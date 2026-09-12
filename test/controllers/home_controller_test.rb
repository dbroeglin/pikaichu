require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:jean_bon)
    @dojo = dojos(:dojo_fr)
  end

  test "should get index" do
    get root_url
    assert_response :success
  end

  %i[en fr].each do |locale|
    test "renders translated navigation in #{locale}" do
      get root_url(locale: locale)

      assert_response :success
      assert_select "html[lang=?]", locale.to_s
      assert_select "a.button", text: I18n.t("home.index.manage_taikais", locale: locale, raise: true)
      assert_select "a.button", text: I18n.t("home.index.manage_dojos", locale: locale, raise: true)
    end
  end
end
