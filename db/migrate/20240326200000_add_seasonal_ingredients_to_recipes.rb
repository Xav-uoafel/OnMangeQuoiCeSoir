class AddSeasonalIngredientsToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_column :recipes, :seasonal_ingredients_used, :json, default: []
  end
end 