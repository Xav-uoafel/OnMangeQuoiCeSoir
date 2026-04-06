class CreateShoppingLists < ActiveRecord::Migration[7.1]
  def change
    create_table :shopping_lists do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, default: 'active'

      t.timestamps
    end
  end
end
