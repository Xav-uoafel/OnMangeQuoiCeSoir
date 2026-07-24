require "test_helper"

class RecipeCostEstimatorTest < ActiveSupport::TestCase
  test "additionne les estimations de reference des ingredients" do
    recipe = recipes(:one)
    recipe.recipe_ingredients = [
      { raw: "200 g de riz", quantity: 200, unit: "g", name: "riz", category: "epicerie" },
      { raw: "2 tomates", quantity: 2, unit: "piece", name: "tomate", category: "legume" }
    ]

    assert_equal 295, RecipeCostEstimator.new(recipe).estimate_cents
  end
end
