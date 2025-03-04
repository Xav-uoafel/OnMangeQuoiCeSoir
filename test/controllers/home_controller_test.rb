require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :success
    assert_select "h1", "On Mange Quoi Ce Soir ?"
  end

  test "should display latest recipes" do
    get root_path
    assert_select ".grid > div", minimum: 1
  end

  test "should show sign up and login links for visitors" do
    get root_path
    assert_select "a[href=?]", new_user_registration_path
    assert_select "a[href=?]", new_user_session_path
  end

  test "should show generate plan link for logged in users" do
    sign_in users(:one)
    get root_path
    assert_select "a[href=?]", new_plan_path
  end
end 