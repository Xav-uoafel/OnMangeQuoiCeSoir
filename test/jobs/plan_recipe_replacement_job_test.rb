require "test_helper"

class PlanRecipeReplacementJobTest < ActiveJob::TestCase
  FakeGenerator = Struct.new(:result) do
    def replace(_plan_recipe)
      result
    end
  end

  setup do
    start_date = Date.current.beginning_of_week(:monday)
    plan = users(:one).plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2 },
      status: "generated"
    )
    @plan_recipe = plan.plan_recipes.create!(
      recipe: recipes(:one),
      scheduled_for: start_date,
      meal_type: "Dîner",
      replacement_status: "generating"
    )
  end

  test "marque le remplacement comme termine" do
    with_generator(FakeGenerator.new(true)) do
      PlanRecipeReplacementJob.perform_now(@plan_recipe.id)
    end

    assert_equal "ready", @plan_recipe.reload.replacement_status
  end

  test "conserve la recette et expose l echec" do
    original_recipe = @plan_recipe.recipe

    with_generator(FakeGenerator.new(false)) do
      PlanRecipeReplacementJob.perform_now(@plan_recipe.id)
    end

    assert_equal "failed", @plan_recipe.reload.replacement_status
    assert_equal original_recipe, @plan_recipe.recipe
  end

  private

  def with_generator(generator)
    original_generator = RecipeGeneratorService.method(:new)
    RecipeGeneratorService.define_singleton_method(:new) { |_plan| generator }
    yield
  ensure
    RecipeGeneratorService.define_singleton_method(:new, original_generator)
  end
end
