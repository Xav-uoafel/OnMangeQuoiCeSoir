require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @recipe = recipes(:one)
    @review = reviews(:one)  # Cette review appartient à @other_user
    sign_in @other_user  # On connecte l'utilisateur qui possède la review
  end

  test "devrait créer une review" do
    # Créer une nouvelle recette sans review pour le test
    recipe = Recipe.create!(
      title: "Nouvelle Recette",
      description: "Description pour test de review",
      ingredients: "Ingrédients test",
      instructions: "Instructions test",
      servings: 4,
      preparation_time: 30,
      cooking_time: 45,
      difficulty: "Facile",
      user: @user,
      generated_at: Time.current
    )

    assert_difference('Review.count') do
      post recipe_reviews_path(recipe), params: {
        review: {
          rating: 4,
          comment: "Un excellent commentaire de test qui fait plus de 10 caractères"
        }
      }
    end

    assert_redirected_to recipe_path(recipe)
    assert_equal I18n.t('flash.review_created'), flash[:notice]
  end

  test "ne devrait pas créer une review invalide" do
    assert_no_difference('Review.count') do
      post recipe_reviews_path(@recipe), params: {
        review: {
          rating: 0,
          comment: "Court"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "ne devrait pas créer une review sans être connecté" do
    sign_out @other_user

    assert_no_difference('Review.count') do
      post recipe_reviews_path(@recipe), params: {
        review: {
          rating: 4,
          comment: "Un excellent commentaire de test"
        }
      }
    end

    assert_redirected_to new_user_session_path
  end

  test "ne devrait pas créer une review sur sa propre recette" do
    sign_in @user  # On connecte le propriétaire de la recette

    assert_no_difference('Review.count') do
      post recipe_reviews_path(@recipe), params: {
        review: {
          rating: 4,
          comment: "Un excellent commentaire de test"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "devrait mettre à jour une review" do
    assert_equal @other_user, @review.user, "La review devrait appartenir à @other_user"
    
    sign_in @review.user
    
    patch recipe_review_path(@recipe, @review), params: {
      review: {
        rating: 5,
        comment: "Un commentaire modifié qui fait plus de 10 caractères"
      }
    }

    assert_redirected_to recipe_path(@recipe)
    assert_equal I18n.t('flash.review_updated'), flash[:notice]
    @review.reload
    assert_equal 5, @review.rating
    assert_equal "Un commentaire modifié qui fait plus de 10 caractères", @review.comment
  end

  test "ne devrait pas mettre à jour la review d'un autre utilisateur" do
    review = reviews(:one)
    sign_in @user # Connecter un utilisateur différent du propriétaire
    original_rating = review.rating

    patch recipe_review_path(@recipe, review), params: {
      review: {
        rating: 2,
        comment: "Une tentative de modification non autorisée"
      }
    }

    assert_response :forbidden
    review.reload
    assert_equal original_rating, review.rating
  end

  test "devrait supprimer une review" do
    review = reviews(:one)
    sign_in review.user

    assert_difference('Review.count', -1) do
      delete recipe_review_path(@recipe, review)
    end

    assert_redirected_to recipe_path(@recipe)
    assert_equal "Commentaire supprimé avec succès", flash[:notice]
  end

  test "ne devrait pas supprimer la review d'un autre utilisateur" do
    review = reviews(:one)
    sign_in @user # Connecter un utilisateur différent du propriétaire

    assert_no_difference('Review.count') do
      delete recipe_review_path(@recipe, review)
    end

    assert_response :forbidden
  end
end
