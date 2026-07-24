class CreatePantryScans < ActiveRecord::Migration[7.1]
  def change
    create_table :pantry_scans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :label
      t.integer :items_detected, default: 0
      t.string :status, default: 'processing'

      t.timestamps
    end
  end
end
