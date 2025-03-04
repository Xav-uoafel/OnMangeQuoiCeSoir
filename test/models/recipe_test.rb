require "test_helper"

class RecipeTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @recipe = Recipe.new(
      title: "Tarte aux pommes",
      description: "Une délicieuse tarte aux pommes traditionnelle",
      ingredients: "Pommes, sucre, pâte brisée, cannelle",
      instructions: "1. Préparer la pâte\n2. Couper les pommes\n3. Assembler et cuire",
      servings: 8,
      preparation_time: 30,
      cooking_time: 45,
      difficulty: "Facile",
      user: @user,
      generated_at: Time.current
    )
  end

  test "recette valide avec tous les attributs" do
    assert @recipe.valid?, "La recette devrait être valide avec tous les attributs requis"
  end

  test "tous les champs sont obligatoires" do
    required_fields = %i[
      title description ingredients instructions 
      servings preparation_time cooking_time difficulty 
      user
    ]

    required_fields.each do |field|
      recipe = @recipe.dup
      recipe.send("#{field}=", nil)
      assert_not recipe.valid?, "#{field} devrait être obligatoire"
      assert_not_empty recipe.errors[field], "Il devrait y avoir une erreur pour #{field}"
    end
  end

  test "validation des formats numériques" do
    numeric_validations = {
      servings: { min: 1, max: 50 },
      preparation_time: { min: 1, max: 1440 },
      cooking_time: { min: 1, max: 1440 }
    }

    numeric_validations.each do |field, constraints|
      # Test valeur trop petite
      @recipe.send("#{field}=", constraints[:min] - 1)
      assert_not @recipe.valid?, "#{field} ne devrait pas accepter #{constraints[:min] - 1}"

      # Test valeur trop grande
      @recipe.send("#{field}=", constraints[:max] + 1)
      assert_not @recipe.valid?, "#{field} ne devrait pas accepter #{constraints[:max] + 1}"

      # Test valeur valide
      @recipe.send("#{field}=", constraints[:min])
      assert @recipe.valid?, "#{field} devrait accepter #{constraints[:min]}"
    end
  end

  test "validation de la difficulté" do
    valid_difficulties = %w[Facile Intermédiaire Difficile]
    invalid_difficulties = ["", "Très facile", "Moyen", "Expert"]

    valid_difficulties.each do |difficulty|
      @recipe.difficulty = difficulty
      assert @recipe.valid?, "#{difficulty} devrait être une difficulté valide"
    end

    invalid_difficulties.each do |difficulty|
      @recipe.difficulty = difficulty
      assert_not @recipe.valid?, "#{difficulty} ne devrait pas être une difficulté valide"
    end
  end

  test "suppression des reviews associées" do
    @recipe.save!
    @recipe.reviews.create!(
      rating: 5,
      comment: "Un excellent commentaire de test qui fait plus de 10 caractères",
      user: users(:two)
    )
    
    assert_difference 'Review.count', -1 do
      @recipe.destroy
    end
  end

  test "generated_at est défini automatiquement si non fourni" do
    recipe = @recipe.dup
    recipe.generated_at = nil
    recipe.save
    assert_not_nil recipe.generated_at, "generated_at devrait être défini automatiquement"
  end

  test "calcul de la note moyenne" do
    recipe = recipes(:one)
    
    Review.create!(
      rating: 4,
      comment: "Premier commentaire de test qui fait plus de 10 caractères",
      recipe: recipe,
      user: users(:two)
    )
    
    Review.create!(
      rating: 2,
      comment: "Deuxième commentaire de test qui fait plus de 10 caractères",
      recipe: recipe,
      user: users(:three)
    )

    assert_equal 3.0, recipe.average_rating
    assert_equal 2, recipe.total_reviews
  end
end
