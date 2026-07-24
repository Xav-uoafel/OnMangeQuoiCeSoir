require "test_helper"

class Pricing::ReferenceCatalogTest < ActiveSupport::TestCase
  test "rounds fractional produce quantities up to whole purchasable items" do
    shopping_list = ShoppingList.new
    item = shopping_list.shopping_list_items.build(
      name: "tomate",
      category: "legume",
      quantity_value: 1.5,
      quantity_unit: "piece"
    )
    catalog = Pricing::ReferenceCatalog.new
    quote = {
      unit_price_cents: 300,
      price_per: "KILOGRAM",
      observed_on: Date.new(2026, 7, 10)
    }

    estimate = catalog.estimate(item, entry: catalog.entry_for(item.name), quote: quote)

    assert_equal 75, estimate[:estimated_price_cents]
    assert_equal "open_prices", estimate[:price_source]
  end
end
