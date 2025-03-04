require "application_system_test_case"

class PlansTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "visiting root redirects to current plan if exists" do
    # Créer un plan en cours
    plan = Plan.create!(
      user: @user,
      start_date: Date.current,
      end_date: Date.current + 7.days,
      constraints: { servings: 4 },
      status: 'generated'
    )

    visit root_path
    assert_current_path plan_path(plan)
  end

  test "visiting root redirects to plans index if has past plans" do
    # Créer un plan passé
    Plan.create!(
      user: @user,
      start_date: Date.current - 14.days,
      end_date: Date.current - 7.days,
      constraints: { servings: 4 },
      status: 'generated'
    )

    visit root_path
    assert_current_path plans_path
  end

  test "visiting root redirects to new plan if no plans exist" do
    visit root_path
    assert_current_path new_plan_path
  end

  test "non-authenticated users cannot access plans" do
    sign_out @user
    visit plans_path
    assert_current_path new_user_session_path
    
    visit new_plan_path
    assert_current_path new_user_session_path
  end

  test "creating a new plan" do
    visit new_plan_path

    fill_in "Nombre de personnes", with: 4
    fill_in "Temps de préparation maximum", with: 45
    check "Végétarien"
    fill_in "Ingrédients à exclure", with: "fruits de mer, noix"
    
    click_on "Créer et générer les recettes"

    assert_text "Plan créé avec succès"
    assert_selector "h1", text: "Plan de repas"
  end
end 