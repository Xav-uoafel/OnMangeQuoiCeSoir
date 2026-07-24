class AddPantryScanToPantryItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :pantry_items, :pantry_scan, foreign_key: true
  end
end
