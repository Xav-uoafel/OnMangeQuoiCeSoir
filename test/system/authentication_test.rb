require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "signs in an existing user" do
    visit new_user_session_path

    fill_in "Adresse email", with: users(:one).email
    fill_in "Mot de passe", with: "password123"
    click_button "Se connecter"

    assert_current_path new_plan_path
    assert_selector "h1", text: "Créer un nouveau plan"
  end

  test "registers and completes onboarding on mobile" do
    use_mobile_viewport
    visit new_user_registration_path

    assert_mobile_registration_layout
    register_mobile_user

    assert_current_path onboarding_path, wait: 5
    assert_selector "h1", text: "Bienvenue sur OnMangeQuoi"

    complete_onboarding

    assert_selector "h1", text: "Créer un nouveau plan"
    assert_current_path new_plan_path, wait: 5
    assert_no_horizontal_overflow
    assert_below_initial_viewport ".mobile-sticky-actions"

    assert_mobile_user_profile
  end

  private

  def assert_mobile_registration_layout
    assert_no_horizontal_overflow
    assert_elements_do_not_overlap(
      "nav[aria-label='Navigation principale'] a[aria-label^='Retour']",
      "nav[aria-label='Navigation principale'] button[data-theme-target='toggle']"
    )
    assert_input_spacing "#user_email"
  end

  def register_mobile_user
    fill_in "Adresse email", with: "mobile@example.com"
    fill_in "Mot de passe", with: "password123"
    fill_in "Confirmer le mot de passe", with: "password123"
    find("#user_password_confirmation").send_keys(:tab)

    assert_field "user_email", with: "mobile@example.com"
    assert_field "user_password", with: "password123"
    assert_field "user_password_confirmation", with: "password123"
    click_button "Créer mon compte"
  end

  def complete_onboarding
    fill_in "Nombre de personnes", with: 3
    check "Végétarien"
    fill_in "Ingrédients à éviter", with: "céleri, cacahuètes"
    fill_in "Préparation maximum (minutes)", with: 35
    click_button "Enregistrer et commencer"
  end

  def assert_mobile_user_profile
    user = User.find_by!(email: "mobile@example.com")
    assert user.onboarding_completed?
    assert_equal 3, user.household_size
    assert_equal 35, user.preferred_max_prep_time
    assert_equal ["céleri", "cacahuètes"], user.excluded_ingredients
  end
end
