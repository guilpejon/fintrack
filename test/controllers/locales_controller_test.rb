require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "sets valid locale in cookie and redirects back" do
    get set_locale_path("pt-BR")
    assert_redirected_to root_path
    assert_equal "pt-BR", cookies[:locale]
  end

  test "sets en locale" do
    get set_locale_path("en")
    assert_redirected_to root_path
    assert_equal "en", cookies[:locale]
  end

  test "sets es locale" do
    get set_locale_path("es")
    assert_redirected_to root_path
    assert_equal "es", cookies[:locale]
  end

  test "rejects invalid locale and falls back to default" do
    get set_locale_path("xx")
    assert_redirected_to root_path
    assert_equal I18n.default_locale.to_s, cookies[:locale]
  end

  test "works without authentication" do
    get set_locale_path("en")
    assert_response :redirect
  end
end
