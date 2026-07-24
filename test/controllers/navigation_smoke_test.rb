require "test_helper"

class NavigationSmokeTest < ActionDispatch::IntegrationTest
  test "visitor pages render their mobile layouts" do
    [
      root_path,
      recipes_path,
      new_user_session_path,
      new_user_registration_path,
      new_user_password_path
    ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render successfully"
    end
  end

  test "authenticated navigation pages render successfully" do
    sign_in users(:one)

    [
      plans_path,
      new_plan_path,
      pantry_items_path,
      new_pantry_scan_path,
      edit_profile_path,
      edit_household_path,
      new_recipe_path,
      recipe_path(recipes(:one))
    ].each do |path|
      get path
      assert_response :success, "Expected #{path} to render successfully"
    end
  end
end
