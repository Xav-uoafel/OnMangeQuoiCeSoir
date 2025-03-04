require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    
    # Créer une nouvelle recette pour les tests
    @recipe = Recipe.create!(
      title: "Recette Test",
      description: "Description test pour les reviews",
      ingredients: "Ingrédients test",
      instructions: "Instructions test",
      servings: 4,
      preparation_time: 30,
      cooking_time: 45,
      difficulty: "Facile",
      user: @user,
      generated_at: Time.current
    )
    
    @review = Review.new(
      rating: 4,
      comment: "Un très bon commentaire de test qui fait plus de 10 caractères",
      recipe: @recipe,
      user: @other_user
    )
  end

  test "review valide avec tous les attributs" do
    assert @review.valid?, "La review devrait être valide avec tous les attributs corrects: #{@review.errors.full_messages}"
  end

  test "rating doit être entre 1 et 5" do
    valid_ratings = [1, 2, 3, 4, 5]
    invalid_ratings = [0, 6, -1, 4.5]

    valid_ratings.each do |rating|
      @review.rating = rating
      assert @review.valid?, "La note #{rating} devrait être valide"
    end

    invalid_ratings.each do |rating|
      @review.rating = rating
      assert_not @review.valid?, "La note #{rating} ne devrait pas être valide"
      assert_includes @review.errors[:rating], "doit être entre 1 et 5"
    end
  end

  test "utilisateur ne peut pas commenter deux fois la même recette" do
    # Créons d'abord une nouvelle recette pour ce test
    recipe = Recipe.create!(
      title: "Recette Test Unique",
      description: "Description test pour review unique",
      ingredients: "Ingrédients test",
      instructions: "Instructions test",
      servings: 4,
      preparation_time: 30,
      cooking_time: 45,
      difficulty: "Facile",
      user: @user,
      generated_at: Time.current
    )

    # Première review - devrait réussir
    first_review = Review.create!(
      rating: 4,
      comment: "Premier commentaire de test qui fait plus de 10 caractères",
      recipe: recipe,
      user: @other_user
    )

    # Deuxième review - devrait échouer
    duplicate_review = Review.new(
      rating: 5,
      comment: "Deuxième commentaire de test qui fait plus de 10 caractères",
      recipe: recipe,
      user: @other_user
    )

    assert_not duplicate_review.valid?
    assert_includes duplicate_review.errors[:user_id], "a déjà commenté cette recette"
  end

  test "commentaire obligatoire" do
    @review.comment = nil
    assert_not @review.valid?
    assert_includes @review.errors[:comment], "Le commentaire ne peut pas être vide"
  end

  test "longueur minimum du commentaire" do
    @review.comment = "Court"
    assert_not @review.valid?
    assert_includes @review.errors[:comment], "doit faire au moins 10 caractères"
  end

  test "review doit appartenir à un utilisateur" do
    @review.user = nil
    assert_not @review.valid?
  end

  test "review doit appartenir à une recette" do
    @review.recipe = nil
    assert_not @review.valid?
  end

  def teardown
    # Nettoyer les recettes créées pendant les tests
    Recipe.where(title: "Recette Test").destroy_all
  end
end
