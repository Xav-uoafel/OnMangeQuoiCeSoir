class AddRatingToRecipes < ActiveRecord::Migration[7.1]
  def change
    add_column :recipes, :rating, :integer, default: 0
  end
end 