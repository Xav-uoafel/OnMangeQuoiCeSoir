class CreateCookedRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :cooked_recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.date :cooked_on, null: false, default: -> { 'CURRENT_DATE' }
      t.boolean :liked

      t.timestamps
    end

    add_index :cooked_recipes, [:user_id, :recipe_id], unique: true
  end
end
