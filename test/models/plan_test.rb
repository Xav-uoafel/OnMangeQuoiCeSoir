require "test_helper"

class PlanTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @plan = Plan.new(
      user: @user,
      start_date: Date.current,
      end_date: Date.current + 7.days,
      constraints: {
        servings: 4,
        max_preparation_time: 45,
        dietary_restrictions: ["Végétarien"],
        excluded_ingredients: "fruits de mer, noix"
      }
    )
  end

  test "plan should be valid" do
    assert @plan.valid?
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
      scheduled_for: Date.current,
      meal_type: "Dîner"
    )

    assert_includes @plan.recipes, recipe
  end
end 