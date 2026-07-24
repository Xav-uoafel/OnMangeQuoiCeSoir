require "test_helper"

class ShoppingListPriceEstimationJobTest < ActiveJob::TestCase
  class FakeEstimator
    def initialize(shopping_list)
      @shopping_list = shopping_list
    end

    def estimate
      raise "Expected estimating status" unless @shopping_list.price_estimation_status == "estimating"

      @shopping_list.shopping_list_items.update_all(
        estimated_price_cents: 250,
        estimated_unit_price_cents: 250,
        price_unit: "paquet",
        price_source: "reference_catalog",
        price_observed_on: Date.new(2026, 7, 1),
        price_confidence: "reference"
      )
      @shopping_list.update!(price_estimation_status: "estimated", prices_estimated_at: Time.current)
    end
  end

  setup do
    user = users(:one)
    start_date = Date.current.beginning_of_week(:monday)
    plan = user.plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      status: "generated",
      constraints: { servings: 2, max_preparation_time: 30, dietary_restrictions: [], excluded_ingredients: [] }
    )
    @shopping_list = plan.create_shopping_list!(user: user)
    @shopping_list.shopping_list_items.create!(name: "riz", quantity_text: "1 kg", category: "epicerie")
  end

  test "estimates prices and renders the Turbo content" do
    original_estimator = GroceryPriceEstimator.method(:new)
    GroceryPriceEstimator.define_singleton_method(:new) { |shopping_list, **_options| FakeEstimator.new(shopping_list) }

    assert_nothing_raised { ShoppingListPriceEstimationJob.perform_now(@shopping_list.id) }
    assert @shopping_list.reload.prices_ready?
    assert_equal 250, @shopping_list.estimated_total_cents

    html = ApplicationController.render(
      partial: "shopping_lists/content",
      locals: {
        plan: @shopping_list.plan,
        shopping_list: @shopping_list,
        items_by_category: @shopping_list.items_by_category
      }
    )
    assert_includes html, 'id="shopping_list_content"'
    assert_includes html, 'aria-busy="false"'
  ensure
    GroceryPriceEstimator.define_singleton_method(:new, original_estimator) if original_estimator
  end
end
