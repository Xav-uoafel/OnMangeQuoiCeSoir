require "test_helper"

class LocalRecipeGeneratorTest < ActiveSupport::TestCase
  test "genere des recettes variees compatibles avec les contraintes" do
    generator = LocalRecipeGenerator.new(
      {
        servings: 3,
        max_preparation_time: 15,
        dietary_restrictions: %w[vegetalien sans_gluten],
        excluded_ingredients: ["tofu"]
      }
    )

    recipes = 4.times.map { generator.generate_recipe }
    recipes.each { |recipe| recipe.user = users(:one) }

    assert_equal 4, recipes.map(&:title).uniq.size
    assert recipes.all?(&:valid?)
    assert recipes.all? { |recipe| recipe.servings == 3 }
    assert recipes.all? { |recipe| recipe.preparation_time <= 15 }
    assert recipes.none? { |recipe| recipe.ingredients.downcase.include?("tofu") }
    assert recipes.all? { |recipe| recipe.recipe_ingredients.present? }
  end

  test "construit une recette sure quand toutes les fiches sont exclues" do
    exclusions = LocalRecipeGenerator::TEMPLATES.flat_map do |template|
      template[:ingredients].map { |ingredient| ingredient[:name] }
    end.uniq

    recipe = LocalRecipeGenerator.new(
      { servings: 2, dietary_restrictions: ["vegetalien"], excluded_ingredients: exclusions }
    ).generate_recipe
    recipe.user = users(:one)

    assert recipe.valid?
    assert_equal 2, recipe.servings
  end
end
