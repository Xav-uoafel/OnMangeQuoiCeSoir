require "test_helper"

class ShoppingListGeneratorTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.pantry_items.create!(name: "tomates", category: "legume", quantity_text: "2", source: "manual", detected_on: Date.current)

    start_date = Date.current - ((Date.current.wday + 6) % 7)
    @plan = @user.plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30, dietary_restrictions: [], excluded_ingredients: [] },
      status: "generated"
    )

    @recipe = @user.recipes.create!(
      title: "Salade test",
      description: "Une recette de test avec placard",
      ingredients: "2 tomates\n1 concombre\n200 g riz",
      instructions: "Mélanger",
      servings: 2,
      preparation_time: 10,
      cooking_time: 10,
      difficulty: "Facile",
      generated_at: Time.current
    )

    @plan.plan_recipes.create!(recipe: @recipe, scheduled_for: start_date, meal_type: "Dîner")
  end

  test "separe les ingredients du placard et ceux a acheter" do
    shopping_list = ShoppingListGenerator.new(@plan).generate

    @recipe.reload

    assert_equal ["tomates"], @recipe.ingredients_from_pantry.map { |item| item["name"] }
    assert_equal ["concombre", "riz"], @recipe.ingredients_to_buy.map { |item| item["name"] }
    assert_equal ["concombre", "riz"], shopping_list.shopping_list_items.order(:name).pluck(:name)
    rice = shopping_list.shopping_list_items.find_by!(name: "riz")
    assert_equal 200, rice.quantity_value
    assert_equal "g", rice.quantity_unit
  end

  test "regroupe les memes ingredients avec conversions d'unites" do
    recipe = @user.recipes.create!(
      title: "Riz au lait test",
      description: "Une recette de test avec conversions",
      ingredients: "1 kg riz\n50 cl lait",
      instructions: "Cuire doucement",
      servings: 2,
      preparation_time: 10,
      cooking_time: 20,
      difficulty: "Facile",
      generated_at: Time.current
    )
    @plan.plan_recipes.create!(recipe: recipe, scheduled_for: @plan.start_date + 1.day, meal_type: "Dîner")

    shopping_list = ShoppingListGenerator.new(@plan).generate

    assert_equal "1.2 kg", shopping_list.shopping_list_items.find_by!(name: "riz").quantity_text
    assert_equal "500 ml", shopping_list.shopping_list_items.find_by!(name: "lait").quantity_text
    assert_equal 1_200, shopping_list.shopping_list_items.find_by!(name: "riz").quantity_value
    assert_equal 500, shopping_list.shopping_list_items.find_by!(name: "lait").quantity_value
  end
end
