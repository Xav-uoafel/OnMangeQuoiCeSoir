class CreateRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :recipes do |t|
      t.string   :title
      t.text     :description
      t.text     :ingredients  
      t.text     :instructions
      t.integer  :servings
      t.integer  :preparation_time
      t.integer  :cooking_time
      t.string   :difficulty
      t.datetime :generated_at
      t.timestamps
    end
  end
end
