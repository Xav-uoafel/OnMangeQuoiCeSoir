class AddUserToRecipes < ActiveRecord::Migration[7.1]
  def up
    # Ajouter d'abord la colonne en permettant les valeurs nulles
    add_reference :recipes, :user, null: true, foreign_key: true

    # Si vous avez déjà un utilisateur dans la base, vous pouvez l'assigner aux recettes existantes
    # Par exemple, prenons le premier utilisateur (ou créons-en un si nécessaire)
    User.first_or_create!(
      email: 'admin@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Assigner toutes les recettes existantes à cet utilisateur
    Recipe.update_all(user_id: User.first.id)

    # Maintenant nous pouvons mettre la contrainte NOT NULL
    change_column_null :recipes, :user_id, false
  end

  def down
    remove_reference :recipes, :user
  end
end 