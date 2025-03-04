require "application_system_test_case"

class RecipesTest < ApplicationSystemTestCase
  setup do
    @recipe = recipes(:one)
    # Créer quelques reviews pour avoir une note moyenne
    @recipe.reviews.create!(rating: 4, comment: "Très bonne recette", user: users(:two))
    @recipe.reviews.create!(rating: 5, comment: "Excellente recette", user: users(:three))
  end

  test "visiting the index" do
    visit recipes_path
    
    assert_selector "h1", text: "Toutes les recettes"
    assert_selector ".recipe", minimum: 1
    
    within("#recipe_#{@recipe.id}") do
      # Vérifie la présence des étoiles
      assert_selector "svg", count: 5 # Il devrait y avoir 5 étoiles au total
      assert_selector "svg.text-yellow-400", minimum: 1 # Au moins une étoile jaune
      assert_selector "svg.text-gray-300", minimum: 1 # Au moins une étoile grise
    end
  end
end 