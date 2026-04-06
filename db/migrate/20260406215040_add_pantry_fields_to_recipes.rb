class AddPantryFieldsToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_column :recipes, :ingredients_from_pantry, :jsonb, default: []
    add_column :recipes, :ingredients_to_buy, :jsonb, default: []
  end
end
