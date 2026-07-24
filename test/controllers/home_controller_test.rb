require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", "On Mange Quoi Ce Soir ?"
  end

  test "should display latest recipes" do
    get root_path
    assert_select ".grid a", minimum: 1
  end

  test "sets restrictive browser security policies" do
    get root_path

    assert_includes response.headers.fetch("Content-Security-Policy"), "default-src 'self'"
    assert_includes response.headers.fetch("Content-Security-Policy"), "frame-ancestors 'none'"
    assert_includes response.headers.fetch("Permissions-Policy"), "camera=(self)"
    assert_includes response.headers.fetch("Permissions-Policy"), "microphone=()"
  end

  test "advertises the installable mobile application" do
    get root_path

    assert_select "link[rel='manifest'][href=?]", pwa_manifest_path(format: :json)
    assert_select "link[rel='apple-touch-icon'][href='/apple-touch-icon.png']"
    assert_select "meta[name='app-environment'][content='test']"
    assert_select "meta[name='mobile-web-app-capable'][content='yes']"
  end

  test "should show sign up and login links for visitors" do
    get root_path
    assert_select "a[href=?]", new_user_registration_path
    assert_select "a[href=?]", new_user_session_path
  end

  test "should show generate plan link for logged in users" do
    sign_in users(:one)
    get root_path
    assert_redirected_to new_plan_path
  end
end
