class AddUserToRecipes < ActiveRecord::Migration[7.1]
  def up
    add_reference :recipes, :user, null: true, foreign_key: true

    User.first_or_create!(
      email: 'admin@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    Recipe.update_all(user_id: User.first.id)

    change_column_null :recipes, :user_id, false
  end

  def down
    remove_reference :recipes, :user
  end
end 