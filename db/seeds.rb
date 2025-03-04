# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Nettoyage de la base de données
puts "Nettoyage de la base de données..."
Review.destroy_all
Recipe.destroy_all
User.destroy_all

# Création des utilisateurs
puts "Création des utilisateurs..."
user1 = User.create!(
  email: "chef@example.com",
  password: "password123",
  password_confirmation: "password123"
)

user2 = User.create!(
  email: "gourmet@example.com",
  password: "password123",
  password_confirmation: "password123"
)

# Création des recettes
puts "Création des recettes..."
recipes_data = [
  {
    title: "Ratatouille Traditionnelle",
    description: "Un plat végétarien traditionnel du sud de la France, parfait pour l'été",
    ingredients: "4 tomates mûres\n2 aubergines\n3 courgettes\n2 poivrons\n1 oignon\nHuile d'olive\nHerbes de Provence\nSel et poivre",
    instructions: "1. Laver et couper tous les légumes en rondelles\n2. Faire revenir l'oignon\n3. Ajouter les légumes un par un\n4. Laisser mijoter à feu doux\n5. Assaisonner en fin de cuisson",
    servings: 6,
    preparation_time: 30,
    cooking_time: 60,
    difficulty: "Intermédiaire",
    user: user1,
    generated_at: Time.current
  },
  {
    title: "Quiche Lorraine",
    description: "La quiche lorraine traditionnelle avec des lardons et de la crème",
    ingredients: "1 pâte brisée\n200g de lardons\n4 œufs\n20cl de crème fraîche\n20cl de lait\nNoix de muscade\nSel et poivre",
    instructions: "1. Préchauffer le four à 180°C\n2. Étaler la pâte dans un moule\n3. Faire revenir les lardons\n4. Mélanger œufs, crème, lait et assaisonnements\n5. Verser sur la pâte\n6. Cuire 45 minutes",
    servings: 6,
    preparation_time: 20,
    cooking_time: 45,
    difficulty: "Facile",
    user: user1,
    generated_at: Time.current
  },
  {
    title: "Tarte Tatin",
    description: "Un classique de la pâtisserie française, avec des pommes caramélisées",
    ingredients: "6 pommes\n1 pâte feuilletée\n150g de sucre\n100g de beurre\n1 pincée de cannelle",
    instructions: "1. Peler et couper les pommes\n2. Faire un caramel avec le sucre\n3. Disposer les pommes\n4. Couvrir de pâte\n5. Cuire 30 minutes\n6. Retourner à chaud",
    servings: 8,
    preparation_time: 40,
    cooking_time: 30,
    difficulty: "Intermédiaire",
    user: user1,
    generated_at: Time.current
  }
]

recipes = recipes_data.map do |recipe_data|
  recipe = Recipe.create!(recipe_data)
  puts "Créé: #{recipe.title}"
  recipe
end

# Création des reviews
puts "Création des reviews..."
reviews_data = [
  {
    rating: 5,
    comment: "Une recette authentique qui rappelle le sud de la France. Les légumes sont parfaitement équilibrés.",
    user: user2,
    recipe: recipes[0]
  },
  {
    rating: 4,
    comment: "Très bonne quiche, mais j'ai ajouté un peu plus de crème pour plus d'onctuosité.",
    user: user2,
    recipe: recipes[1]
  },
  {
    rating: 5,
    comment: "La meilleure tarte tatin que j'ai jamais faite ! Le caramel était parfait.",
    user: user2,
    recipe: recipes[2]
  }
]

reviews_data.each do |review_data|
  review = Review.create!(review_data)
  puts "Créé: Review pour #{review.recipe.title}"
end

puts "Seed terminé avec succès !"
puts "Créé: #{User.count} utilisateurs"
puts "Créé: #{Recipe.count} recettes"
puts "Créé: #{Review.count} reviews"
