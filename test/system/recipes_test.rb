require "application_system_test_case"

class RecipesTest < ApplicationSystemTestCase
  setup do
    @recipe = recipes(:one)
  end

  test "lists recipes with an accessible rating" do
    visit recipes_path

    assert_selector "h1", text: "Toutes les recettes"
    assert_selector ".recipe", minimum: 1

    within("#recipe_#{@recipe.id}") do
      assert_selector "[aria-label='Note moyenne : 4.0 sur 5']"
      assert_selector "svg", count: 5
      assert_selector "svg.text-yellow-300", count: 4
      assert_selector "svg.text-gray-300", count: 1
    end
  end

  test "filters the catalogue by title" do
    visit recipes_path

    fill_in "Rechercher une recette", with: "Tarte"
    click_button "Rechercher"

    assert_selector "#recipe_#{recipes(:one).id}"
    assert_no_selector "#recipe_#{recipes(:two).id}"
  end
end
