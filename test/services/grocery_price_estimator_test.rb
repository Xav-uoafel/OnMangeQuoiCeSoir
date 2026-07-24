require "test_helper"

class GroceryPriceEstimatorTest < ActiveSupport::TestCase
  class FakeOpenPrices
    def quote_for(category_tag:, preferred_price_units:)
      return unless category_tag == "en:tomatoes" && preferred_price_units.include?("KILOGRAM")

      {
        unit_price_cents: 300,
        price_per: "KILOGRAM",
        observed_on: Date.new(2026, 7, 10),
        sample_size: 4
      }
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
    @shopping_list = plan.create_shopping_list!(user: user, price_estimation_status: "estimating")
    @tomatoes = @shopping_list.shopping_list_items.create!(
      name: "tomate",
      category: "legume",
      quantity_text: "500 g",
      quantity_value: 500,
      quantity_unit: "g"
    )
    @rice = @shopping_list.shopping_list_items.create!(
      name: "riz",
      category: "epicerie",
      quantity_text: "200 g",
      quantity_value: 200,
      quantity_unit: "g"
    )
  end

  test "combines observed prices and reference package prices" do
    GroceryPriceEstimator.new(@shopping_list, open_prices: FakeOpenPrices.new).estimate

    assert_equal 150, @tomatoes.reload.estimated_price_cents
    assert_equal "open_prices", @tomatoes.price_source
    assert_equal Date.new(2026, 7, 10), @tomatoes.price_observed_on
    assert_equal 220, @rice.reload.estimated_price_cents
    assert_equal "reference_catalog", @rice.price_source
    assert_equal 370, @shopping_list.reload.estimated_total_cents
    assert_equal 50, @shopping_list.observed_price_percentage
    assert @shopping_list.prices_ready?
  end

  test "normalizes quantities from a shopping list created before pricing" do
    @rice.update!(quantity_value: nil, quantity_unit: nil, quantity_text: "1.2 kg")

    GroceryPriceEstimator.new(@shopping_list, open_prices: FakeOpenPrices.new).estimate

    assert_equal 1_200, @rice.reload.quantity_value
    assert_equal "g", @rice.quantity_unit
    assert_equal 440, @rice.estimated_price_cents
  end
end
