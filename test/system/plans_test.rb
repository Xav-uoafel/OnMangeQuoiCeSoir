require "application_system_test_case"

class PlansTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @week_start = Date.current.beginning_of_week(:monday)
    sign_in_as @user
  end

  test "root redirects to the current generated plan" do
    plan = create_plan(start_date: @week_start, status: "generated")

    visit root_path

    assert_current_path plan_path(plan)
    assert_selector "h1", text: "Plan de repas"
  end

  test "root redirects to plan history when only past plans exist" do
    create_plan(start_date: @week_start - 2.weeks, status: "generated")

    visit root_path

    assert_current_path plans_path
    assert_selector "h1", text: "Mes plans"
  end

  test "root redirects to plan creation when no plan exists" do
    visit root_path

    assert_current_path new_plan_path
    assert_selector "h1", text: "Créer un nouveau plan"
  end

  test "anonymous visitors are redirected to sign in" do
    logout(:user)

    visit plans_path
    assert_current_path new_user_session_path

    visit new_plan_path
    assert_current_path new_user_session_path
  end

  test "creates a weekly plan and enqueues recipe generation" do
    visit new_plan_path

    assert_field "Date de début", with: @week_start.iso8601
    assert_field "Date de fin", with: (@week_start + 6.days).iso8601
    fill_in "Nombre de personnes", with: 4
    fill_in "Préparation maximum (minutes)", with: 45
    fill_in "Budget courses pour la semaine", with: "80"
    check "Végétarien"
    fill_in "Ingrédients à exclure", with: "fruits de mer, noix"

    assert_enqueued_with(job: RecipeGenerationJob) do
      click_button "Créer et générer"
      assert_text "Plan créé ! Génération des recettes en cours..."
    end

    plan = @user.plans.order(:created_at).last
    assert_current_path plan_path(plan)
    assert_selector "h1", text: "Plan de repas"
    assert_text "Génération en cours..."
    assert plan.generating?
    assert_equal 8_000, plan.weekly_budget_cents
    assert_includes plan.constraints.fetch("dietary_restrictions"), "vegetarien"
    assert_equal ["fruits de mer", "noix"], plan.constraints.fetch("excluded_ingredients")
  end

  test "offers a clear retry when generation is stale" do
    plan = create_plan(start_date: @week_start, status: "generating")
    plan.update!(
      generation_token: SecureRandom.uuid,
      generation_started_at: 11.minutes.ago,
      generation_attempts: 1
    )

    visit plan_path(plan)

    assert_text "La génération semble bloquée"
    assert_button "Relancer maintenant"
    assert_minimum_touch_target "form[action='#{generate_plan_path(plan)}'] button"
  end

  test "renders the standalone offline screen" do
    visit offline_path

    assert_selector "h1", text: "Le réseau fait une pause"
    assert_link "Réessayer", href: root_path
  end

  private

  def create_plan(start_date:, status:)
    @user.plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30 },
      status: status
    )
  end
end
