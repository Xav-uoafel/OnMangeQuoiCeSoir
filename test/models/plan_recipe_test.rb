require "test_helper"

class PlanRecipeTest < ActiveSupport::TestCase
  setup do
    start_date = Date.current.beginning_of_week(:monday)
    plan = users(:one).plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2 }
    )
    @plan_recipe = plan.plan_recipes.build(
      recipe: recipes(:one),
      scheduled_for: start_date,
      meal_type: "Dîner"
    )
  end

  test "utilise un statut de remplacement pret par defaut" do
    assert @plan_recipe.valid?
    assert_equal "ready", @plan_recipe.replacement_status
  end

  test "refuse un statut de remplacement inconnu" do
    @plan_recipe.replacement_status = "unknown"

    assert_not @plan_recipe.valid?
  end
end
