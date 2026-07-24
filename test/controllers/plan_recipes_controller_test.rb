require "test_helper"

class PlanRecipesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    start_date = Date.current.beginning_of_week(:monday)
    @plan = @user.plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2 },
      status: "generated"
    )
    @plan_recipe = @plan.plan_recipes.create!(
      recipe: recipes(:one),
      scheduled_for: start_date,
      meal_type: "Dîner"
    )
    sign_in @user
  end

  test "verrouille et deverrouille un repas" do
    patch toggle_lock_plan_plan_recipe_path(@plan, @plan_recipe)
    assert_redirected_to plan_path(@plan, anchor: "plan_recipe_#{@plan_recipe.id}")
    assert @plan_recipe.reload.locked?

    patch toggle_lock_plan_plan_recipe_path(@plan, @plan_recipe)
    assert_not @plan_recipe.reload.locked?
  end

  test "programme le remplacement asynchrone" do
    assert_enqueued_with(job: PlanRecipeReplacementJob, args: [@plan_recipe.id]) do
      post replace_plan_plan_recipe_path(@plan, @plan_recipe)
    end

    assert_redirected_to plan_path(@plan, anchor: "plan_recipe_#{@plan_recipe.id}")
    assert @plan_recipe.reload.replacement_generating?
  end

  test "refuse de remplacer un repas verrouille" do
    @plan_recipe.update!(locked: true)

    assert_no_enqueued_jobs only: PlanRecipeReplacementJob do
      post replace_plan_plan_recipe_path(@plan, @plan_recipe)
    end

    assert_redirected_to plan_path(@plan)
    assert_equal "ready", @plan_recipe.reload.replacement_status
  end

  test "expose un echec quand le remplacement ne peut pas etre programme" do
    failed_job = Struct.new(:successfully_enqueued?).new(false)
    original_enqueue = PlanRecipeReplacementJob.method(:perform_later)
    PlanRecipeReplacementJob.define_singleton_method(:perform_later) { |_id| failed_job }

    post replace_plan_plan_recipe_path(@plan, @plan_recipe)

    assert_redirected_to plan_path(@plan, anchor: "plan_recipe_#{@plan_recipe.id}")
    assert @plan_recipe.reload.replacement_failed?
  ensure
    PlanRecipeReplacementJob.define_singleton_method(:perform_later, original_enqueue) if original_enqueue
  end

  test "ne permet pas de manipuler le repas d un autre utilisateur" do
    sign_out @user
    sign_in users(:two)

    patch toggle_lock_plan_plan_recipe_path(@plan, @plan_recipe)

    assert_response :not_found
    assert_not @plan_recipe.reload.locked?
  end
end
