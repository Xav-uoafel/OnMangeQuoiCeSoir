class AddPriceEstimatesToShoppingLists < ActiveRecord::Migration[8.0]
  def change
    add_column :shopping_lists, :price_estimation_status, :string, null: false, default: "pending"
    add_column :shopping_lists, :prices_estimated_at, :datetime

    add_column :shopping_list_items, :quantity_value, :decimal, precision: 10, scale: 3
    add_column :shopping_list_items, :quantity_unit, :string
    add_column :shopping_list_items, :estimated_price_cents, :integer
    add_column :shopping_list_items, :estimated_unit_price_cents, :integer
    add_column :shopping_list_items, :price_unit, :string
    add_column :shopping_list_items, :price_source, :string
    add_column :shopping_list_items, :price_observed_on, :date
    add_column :shopping_list_items, :price_confidence, :string

    add_index :shopping_lists, :price_estimation_status
    add_index :shopping_list_items, :price_source
  end
end
