require "test_helper"

class PlanTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    today = Date.current
    start_date = today - ((today.wday + 6) % 7)
    @plan = Plan.new(
      user: @user,
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: {
        servings: 4,
        max_preparation_time: 45,
        dietary_restrictions: ["Végétarien"],
        excluded_ingredients: ["fruits de mer", "noix"]
      }
    )
  end

  test "plan should be valid" do
    assert @plan.valid?
  end

  test "preserve les contraintes apres serialisation JSON" do
    @plan.save!
    @plan.reload

    assert_equal 4, @plan.constraints["servings"]
    assert_equal 45, @plan.constraints["max_preparation_time"]
    assert_equal ["Végétarien"], @plan.constraints["dietary_restrictions"]
  end

  test "complete les contraintes manquantes avec le profil" do
    @user.update!(household_size: 3, preferred_max_prep_time: 30)
    @plan.constraints = { "servings" => nil, "max_preparation_time" => nil }
    @plan.valid?

    assert_equal 3, @plan.constraints["servings"]
    assert_equal 30, @plan.constraints["max_preparation_time"]
  end

  test "plan should have a user" do
    @plan.user = nil
    assert_not @plan.valid?
  end

  test "end date should be after start date" do
    @plan.end_date = @plan.start_date - 1.day
    assert_not @plan.valid?
    assert_includes @plan.errors[:end_date], "doit être après la date de début"
  end

  test "constraints should be present" do
    @plan.constraints = nil
    assert_not @plan.valid?
  end

  test "should have status draft by default" do
    plan = Plan.new
    assert_equal "draft", plan.status
  end

  test "should have associated recipes through plan_recipes" do
    @plan.save!
    recipe = recipes(:one)
    
    @plan.plan_recipes.create!(
      recipe: recipe,
      scheduled_for: @plan.start_date,
      meal_type: "Dîner"
    )

    assert_includes @plan.recipes, recipe
  end

  test "normalise le budget et calcule une cible par repas" do
    @plan.assign_attributes(
      weekday_lunches: false,
      weekday_dinners: true,
      weekend_lunches: false,
      weekend_dinners: false,
      constraints: @plan.constraints.merge(weekly_budget_cents: 5_000)
    )

    assert @plan.valid?
    assert_equal 5_000, @plan.weekly_budget_cents
    assert_equal 5, @plan.planned_meals_count
    assert_equal 1_000, @plan.target_cost_per_meal_cents
  end

  test "refuse un budget negatif" do
    @plan.constraints = @plan.constraints.merge(weekly_budget_cents: -100)

    assert_not @plan.valid?
    assert @plan.errors[:constraints].any?
  end

  test "compare le panier estime au budget" do
    @plan.constraints = @plan.constraints.merge(weekly_budget_cents: 5_000)
    @plan.save!
    shopping_list = @plan.create_shopping_list!(user: @user, price_estimation_status: "estimated")
    shopping_list.shopping_list_items.create!(name: "riz", estimated_price_cents: 5_500)

    assert @plan.over_budget?
    assert_equal(-500, @plan.budget_difference_cents)
    assert_equal 110, @plan.budget_usage_percentage
  end
end
