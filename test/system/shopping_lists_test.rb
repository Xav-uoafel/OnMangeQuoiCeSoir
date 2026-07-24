require "application_system_test_case"

class ShoppingListsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @week_start = Date.current.beginning_of_week(:monday)
    @plan = @user.plans.create!(
      start_date: @week_start,
      end_date: @week_start + 6.days,
      constraints: { servings: 2, max_preparation_time: 30, weekly_budget_cents: 6_000 },
      status: "generated"
    )
    recipe = @user.recipes.create!(
      title: "Pâtes aux tomates de test",
      description: "Une recette complète réservée au parcours de liste de courses.",
      ingredients: "200 g de pâtes\n500 g de tomates",
      recipe_ingredients: [
        { name: "pâtes", quantity: 200, unit: "g", category: "epicerie" },
        { name: "tomates", quantity: 500, unit: "g", category: "legume" }
      ],
      instructions: "Cuire les pâtes, ajouter les tomates puis servir.",
      servings: 2,
      preparation_time: 10,
      cooking_time: 15,
      difficulty: "Facile"
    )
    @plan.plan_recipes.create!(recipe: recipe, scheduled_for: @week_start, meal_type: "Dîner")
    sign_in_as @user
  end

  test "generates a shopping list and persists checked items" do
    assert_enqueued_with(job: ShoppingListPriceEstimationJob) do
      visit plan_shopping_list_path(@plan)
      assert_selector "h1", text: "Liste de courses"
    end

    assert_text "pâtes"
    assert_text "tomates"
    assert_text "Calcul du panier..."

    checkbox = find("input[type='checkbox'][aria-label*='tomates']")
    checkbox.check

    assert_text "Liste mise a jour."
    assert @plan.shopping_list.shopping_list_items.find_by!(name: "tomates").checked?
  end
end
