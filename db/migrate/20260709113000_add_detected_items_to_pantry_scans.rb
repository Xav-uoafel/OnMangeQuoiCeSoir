class AddDetectedItemsToPantryScans < ActiveRecord::Migration[8.0]
  def change
    add_column :pantry_scans, :detected_items, :jsonb, default: [], null: false
  end
end
