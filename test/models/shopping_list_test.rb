require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  setup do
    @shopping_list = create_shopping_list
  end

  test "calcule les metriques depuis les articles precharges sans nouvelle requete" do
    @shopping_list.items_by_category

    assert_no_queries do
      assert_equal 2, @shopping_list.total_items_count
      assert_equal 1, @shopping_list.checked_items_count
      assert_equal 1, @shopping_list.remaining_items_count
      assert_equal 50, @shopping_list.progress_percentage
      assert_equal 430, @shopping_list.estimated_total_cents
      assert_equal 180, @shopping_list.remaining_total_cents
      assert_equal 100, @shopping_list.price_coverage_percentage
      assert_equal 50, @shopping_list.observed_price_percentage
      assert_equal Date.current, @shopping_list.latest_price_observed_on
    end
  end

  private

  def create_shopping_list
    shopping_list = create_plan.create_shopping_list!(
      user: users(:one),
      price_estimation_status: "estimated"
    )
    add_items(shopping_list)
    shopping_list
  end

  def create_plan
    start_date = Date.current.beginning_of_week(:monday)
    users(:one).plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30 },
      status: "generated"
    )
  end

  def add_items(shopping_list)
    shopping_list.shopping_list_items.create!(
      name: "Pommes",
      category: "fruits",
      checked: true,
      estimated_price_cents: 250,
      price_source: "open_prices",
      price_observed_on: Date.current
    )
    shopping_list.shopping_list_items.create!(
      name: "Riz",
      category: "epicerie",
      estimated_price_cents: 180,
      price_source: "reference_catalog",
      price_observed_on: Date.current - 1.day
    )
  end
end
