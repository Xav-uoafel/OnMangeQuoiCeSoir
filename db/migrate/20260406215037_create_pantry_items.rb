class CreatePantryItems < ActiveRecord::Migration[7.1]
  def change
    create_table :pantry_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :category
      t.string :quantity_text
      t.date :detected_on
      t.string :source

      t.timestamps
    end
  end
end
