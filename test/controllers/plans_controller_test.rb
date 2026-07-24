require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @start_date = Date.current.beginning_of_week(:monday)
    sign_in @user
  end

  test "enregistre le budget lors de la creation" do
    assert_enqueued_with(job: RecipeGenerationJob) do
      post plans_path, params: {
        plan: {
          start_date: @start_date,
          end_date: @start_date + 6.days,
          weekday_dinners: "1",
          weekend_lunches: "1",
          weekend_dinners: "1",
          constraints_servings: "2",
          constraints_max_preparation_time: "30",
          constraints_weekly_budget: "75.50"
        }
      }
    end

    plan = @user.plans.order(:created_at).last
    assert_redirected_to plan_path(plan)
    assert_equal 7_550, plan.weekly_budget_cents
  end

  test "met a jour ou retire le budget" do
    plan = create_plan

    patch plan_path(plan), params: { plan: { weekly_budget: "90.25" } }
    assert_redirected_to plan_path(plan)
    assert_equal 9_025, plan.reload.weekly_budget_cents

    patch plan_path(plan), params: { plan: { weekly_budget: "" } }
    assert_redirected_to plan_path(plan)
    assert_nil plan.reload.weekly_budget_cents
  end

  test "conserve les repas verrouilles pendant une regeneration" do
    plan = create_plan(status: "generated")
    locked = plan.plan_recipes.create!(
      recipe: recipes(:one),
      scheduled_for: @start_date,
      meal_type: "Dîner",
      locked: true
    )
    unlocked = plan.plan_recipes.create!(
      recipe: recipes(:two),
      scheduled_for: @start_date + 1.day,
      meal_type: "Dîner"
    )
    shopping_list = plan.create_shopping_list!(user: @user)

    assert_enqueued_with(job: RecipeGenerationJob) do
      post generate_plan_path(plan)
    end

    assert_redirected_to plan_path(plan)
    assert PlanRecipe.exists?(locked.id)
    assert_not PlanRecipe.exists?(unlocked.id)
    assert_not ShoppingList.exists?(shopping_list.id)
    assert plan.reload.generating?
    assert_not_nil plan.generation_token
    assert_equal plan.generation_token, enqueued_jobs.last.fetch(:args).second
  end

  private

  def create_plan(status: "draft")
    @user.plans.create!(
      start_date: @start_date,
      end_date: @start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30 },
      status: status
    )
  end
end
