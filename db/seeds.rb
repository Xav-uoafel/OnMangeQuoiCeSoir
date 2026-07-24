# Demo data is safe to run repeatedly and never deletes existing records.
seed_demo_data = Rails.env.development? || ActiveModel::Type::Boolean.new.cast(ENV.fetch("SEED_DEMO_DATA", nil))

def create_demo_data!
  puts "Création des données de démonstration..."

  demo_users = {
    chef: {
      email: "chef@example.com",
      password: "password123",
      household_size: 4,
      preferred_max_prep_time: 45
    },
    gourmet: {
      email: "gourmet@example.com",
      password: "password123",
      household_size: 2,
      preferred_max_prep_time: 35
    }
  }

  users = demo_users.transform_values do |attributes|
    user = User.find_or_initialize_by(email: attributes.fetch(:email))
    if user.new_record?
      user.password = attributes.fetch(:password)
      user.password_confirmation = attributes.fetch(:password)
    end
    user.assign_attributes(
      onboarding_completed: true,
      household_size: attributes.fetch(:household_size),
      preferred_max_prep_time: attributes.fetch(:preferred_max_prep_time)
    )
    user.save!
    user
  end

  recipes_data = [
    {
      title: "Ratatouille traditionnelle",
      description: "Un plat végétarien traditionnel du sud de la France, parfait pour l'été.",
      ingredients: "4 tomates mûres\n2 aubergines\n3 courgettes\n2 poivrons\n1 oignon\nHuile d'olive\nHerbes de Provence\nSel et poivre",
      instructions: "1. Laver et couper tous les légumes en rondelles\n2. Faire revenir l'oignon\n3. Ajouter les légumes un par un\n4. Laisser mijoter à feu doux\n5. Assaisonner en fin de cuisson",
      servings: 6,
      preparation_time: 30,
      cooking_time: 60,
      difficulty: "Intermédiaire"
    },
    {
      title: "Quiche lorraine",
      description: "La quiche lorraine traditionnelle avec des lardons et de la crème.",
      ingredients: "1 pâte brisée\n200 g de lardons\n4 œufs\n20 cl de crème fraîche\n20 cl de lait\nNoix de muscade\nSel et poivre",
      instructions: "1. Préchauffer le four à 180 °C\n2. Étaler la pâte dans un moule\n3. Faire revenir les lardons\n4. Mélanger les œufs, la crème et le lait\n5. Verser sur la pâte\n6. Cuire 45 minutes",
      servings: 6,
      preparation_time: 20,
      cooking_time: 45,
      difficulty: "Facile"
    },
    {
      title: "Tarte Tatin",
      description: "Un classique de la pâtisserie française avec des pommes caramélisées.",
      ingredients: "6 pommes\n1 pâte feuilletée\n150 g de sucre\n100 g de beurre\n1 pincée de cannelle",
      instructions: "1. Peler et couper les pommes\n2. Faire un caramel avec le sucre\n3. Disposer les pommes\n4. Couvrir de pâte\n5. Cuire 30 minutes\n6. Retourner à chaud",
      servings: 8,
      preparation_time: 40,
      cooking_time: 30,
      difficulty: "Intermédiaire"
    }
  ]

  recipes = recipes_data.map do |attributes|
    recipe = Recipe.find_or_initialize_by(title: attributes.fetch(:title), user: users.fetch(:chef))
    recipe.assign_attributes(attributes.merge(generated_at: recipe.generated_at || Time.current))
    recipe.save!
    recipe
  end

  reviews_data = [
    {
      recipe: recipes[0],
      rating: 5,
      comment: "Une recette authentique qui rappelle le sud de la France. Les légumes sont parfaitement équilibrés."
    },
    {
      recipe: recipes[1],
      rating: 4,
      comment: "Très bonne quiche, avec une texture particulièrement onctueuse."
    },
    {
      recipe: recipes[2],
      rating: 5,
      comment: "Une excellente tarte Tatin, simple à préparer et bien caramélisée."
    }
  ]

  reviews_data.each do |attributes|
    review = Review.find_or_initialize_by(user: users.fetch(:gourmet), recipe: attributes.fetch(:recipe))
    review.assign_attributes(attributes.slice(:rating, :comment))
    review.save!
  end

  puts "Données prêtes : #{users.size} utilisateurs, #{recipes.size} recettes et #{reviews_data.size} avis."
  puts "Comptes de démonstration : chef@example.com et gourmet@example.com (mot de passe : password123)."
end

if seed_demo_data
  create_demo_data!
else
  puts "Données de démonstration ignorées. Utilisez SEED_DEMO_DATA=1 pour les créer explicitement."
end
