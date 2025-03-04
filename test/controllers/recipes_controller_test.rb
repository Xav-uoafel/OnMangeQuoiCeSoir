require "test_helper"

class RecipesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @recipe = recipes(:one)
    sign_in @user
  end

  test "devrait afficher l'index" do
    get recipes_path
    assert_response :success
    assert_select 'h1', 'Liste des Recettes'
    assert_select '.recipe', minimum: 2  # Changé de recipe-card à recipe
  end

  test "devrait afficher une recette" do
    get recipe_path(@recipe)
    assert_response :success
    assert_select 'h1', @recipe.title
    assert_select '.ingredients', /#{Regexp.escape(@recipe.ingredients)}/
    assert_select '.instructions' do |element|
      assert_match(/#{Regexp.escape(@recipe.instructions)}/, element.text.strip)
    end
  end

  test "devrait afficher le formulaire de nouvelle recette" do
    get new_recipe_path
    assert_response :success
    assert_select 'form[action=?]', recipes_path
    assert_select 'input[name="recipe[title]"]'
    assert_select 'textarea[name="recipe[ingredients]"]'
  end

  test "devrait créer une recette" do
    assert_difference('Recipe.count') do
      post recipes_path, params: {
        recipe: {
          title: "Nouvelle Recette Test",
          description: "Une description détaillée de la recette de test",
          ingredients: "Ingrédient 1, Ingrédient 2",
          instructions: "1. Étape 1\n2. Étape 2",
          servings: 4,
          preparation_time: 30,
          cooking_time: 45,
          difficulty: "Facile"
        }
      }
    end

    assert_redirected_to recipe_path(Recipe.last)
    assert_equal I18n.t('flash.recipe_created'), flash[:notice]
    assert_equal @user.id, Recipe.last.user_id
  end

  test "ne devrait pas créer une recette invalide" do
    assert_no_difference('Recipe.count') do
      post recipes_path, params: {
        recipe: {
          title: "",  # titre vide invalide
          description: "Description test"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_not_empty flash[:error]
  end

  test "devrait afficher le formulaire d'édition" do
    get edit_recipe_path(@recipe)
    assert_response :success
    assert_select 'form[action=?]', recipe_path(@recipe)
    assert_select 'input[name="recipe[title]"][value=?]', @recipe.title
  end

  test "devrait mettre à jour une recette" do
    patch recipe_path(@recipe), params: {
      recipe: {
        title: "Titre Modifié",
        description: "Description modifiée"
      }
    }

    assert_redirected_to recipe_path(@recipe)
    assert_equal I18n.t('flash.recipe_updated'), flash[:notice]
    @recipe.reload
    assert_equal "Titre Modifié", @recipe.title
  end

  test "ne devrait pas mettre à jour la recette d'un autre utilisateur" do
    sign_in @other_user
    patch recipe_path(@recipe), params: {
      recipe: { title: "Tentative de modification" }
    }

    assert_response :forbidden
    @recipe.reload
    assert_not_equal "Tentative de modification", @recipe.title
  end

  test "devrait supprimer une recette" do
    assert_difference('Recipe.count', -1) do
      delete recipe_path(@recipe)
    end

    assert_redirected_to recipes_path
    assert_equal I18n.t('flash.recipe_deleted'), flash[:notice]
  end

  test "ne devrait pas supprimer la recette d'un autre utilisateur" do
    sign_in @other_user
    assert_no_difference('Recipe.count') do
      delete recipe_path(@recipe)
    end

    assert_response :forbidden
  end

  test "devrait rediriger vers la connexion si non authentifié" do
    sign_out @user
    get new_recipe_path
    assert_redirected_to new_user_session_path
  end

  test "devrait filtrer les recettes par difficulté" do
    get recipes_path, params: { difficulty: "Facile" }
    assert_response :success
    assert_select '.recipe', text: /#{@recipe.title}/  # Changé de recipe-card
  end

  test "devrait rechercher des recettes par titre" do
    get recipes_path, params: { search: "Tarte" }
    assert_response :success
    assert_select '.recipe', text: /Tarte/  # Changé de recipe-card
  end
end
