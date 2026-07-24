class CreateShoppingListItems < ActiveRecord::Migration[7.1]
  def change
    create_table :shopping_list_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.string :name, null: false
      t.string :quantity_text
      t.string :category
      t.boolean :checked, default: false

      t.timestamps
    end
  end
end
