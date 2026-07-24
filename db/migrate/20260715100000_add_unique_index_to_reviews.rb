class AddUniqueIndexToReviews < ActiveRecord::Migration[8.0]
  INDEX_NAME = "index_reviews_on_user_id_and_recipe_id".freeze

  def up
    execute <<~SQL.squish
      DELETE FROM reviews AS duplicate
      USING reviews AS original
      WHERE duplicate.user_id = original.user_id
        AND duplicate.recipe_id = original.recipe_id
        AND duplicate.id > original.id
    SQL

    add_index :reviews, %i[user_id recipe_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_index :reviews, name: INDEX_NAME
  end
end
