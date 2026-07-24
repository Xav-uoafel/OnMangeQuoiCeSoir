class AddRecipeIngredientsToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :recipe_ingredients, :jsonb, default: [], null: false
  end
end
