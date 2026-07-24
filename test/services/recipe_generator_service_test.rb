require "test_helper"

class RecipeGeneratorServiceTest < ActiveSupport::TestCase
  class FakeRecipeGenerator
    attr_reader :calls

    def initialize(recipes)
      @recipes = recipes
      @calls = 0
    end

    def generate_recipe
      @calls += 1
      @recipes.shift
    end
  end

  class UnavailableRecipeGenerator
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def generate_recipe
      @calls += 1
      raise LLM::RecipeGenerator::GenerationError.new("quota", code: "insufficient_quota")
    end
  end

  def setup
    @user = users(:one)
    start_date = Date.current - ((Date.current.wday + 6) % 7)
    @plan = @user.plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30, dietary_restrictions: [], excluded_ingredients: [] },
      weekday_lunches: false,
      weekday_dinners: true,
      weekend_lunches: false,
      weekend_dinners: false
    )
  end

  test "retente une generation quand une recette duplique trop une precedente" do
    fake_generator = FakeRecipeGenerator.new([
      recipe_candidate("Riz tomates", "200 g riz\n2 tomates"),
      recipe_candidate("Riz tomates", "200 g riz\n2 tomates"),
      recipe_candidate("Pates courgettes", "200 g pâtes\n2 courgettes"),
      recipe_candidate("Poulet citron", "2 filets poulet\n1 citron"),
      recipe_candidate("Omelette champignons", "4 oeufs\n200 g champignons"),
      recipe_candidate("Saumon quinoa", "2 pavés saumon\n150 g quinoa")
    ])

    assert RecipeGeneratorService.new(@plan, recipe_generator: fake_generator).generate

    titles = @plan.recipes.order(:created_at).pluck(:title)
    assert_equal 6, fake_generator.calls
    assert_equal 5, @plan.plan_recipes.count
    assert_equal ["Riz tomates", "Pates courgettes", "Poulet citron", "Omelette champignons", "Saumon quinoa"], titles
  end

  test "termine le plan avec le generateur local quand OpenAI est indisponible" do
    unavailable_generator = UnavailableRecipeGenerator.new
    service = RecipeGeneratorService.new(@plan, recipe_generator: unavailable_generator)

    assert service.generate
    assert service.fallback_used?
    assert_equal 1, unavailable_generator.calls
    assert_equal 5, @plan.plan_recipes.count
    assert @plan.recipes.all? { |recipe| recipe.user == @user }
  end

  test "ne regenere pas un creneau deja occupe" do
    @plan.plan_recipes.create!(
      recipe: recipes(:one),
      scheduled_for: @plan.start_date,
      meal_type: "Dîner",
      locked: true
    )
    fake_generator = FakeRecipeGenerator.new([
      recipe_candidate("Pates courgettes", "200 g pâtes\n2 courgettes"),
      recipe_candidate("Poulet citron", "2 filets poulet\n1 citron"),
      recipe_candidate("Omelette champignons", "4 oeufs\n200 g champignons"),
      recipe_candidate("Saumon quinoa", "2 pavés saumon\n150 g quinoa")
    ])

    assert RecipeGeneratorService.new(@plan, recipe_generator: fake_generator).generate
    assert_equal 4, fake_generator.calls
    assert_equal 5, @plan.plan_recipes.count
    assert_equal recipes(:one), @plan.plan_recipes.find_by(scheduled_for: @plan.start_date).recipe
  end

  test "remplace uniquement la recette cible et invalide la liste de courses" do
    plan_recipe = @plan.plan_recipes.create!(
      recipe: recipes(:one),
      scheduled_for: @plan.start_date,
      meal_type: "Dîner"
    )
    shopping_list = @plan.create_shopping_list!(user: @user)
    fake_generator = FakeRecipeGenerator.new([
      recipe_candidate("Pates courgettes", "200 g pâtes\n2 courgettes")
    ])

    assert RecipeGeneratorService.new(@plan, recipe_generator: fake_generator).replace(plan_recipe)

    assert_equal "Pates courgettes", plan_recipe.reload.recipe.title
    assert_not ShoppingList.exists?(shopping_list.id)
    assert_equal 1, @plan.plan_recipes.count
  end

  private

  def recipe_candidate(title, ingredients)
    Recipe.new(
      title: title,
      description: "Description complete pour #{title}",
      ingredients: ingredients,
      instructions: "Préparer les ingrédients puis servir.",
      servings: 2,
      preparation_time: 10,
      cooking_time: 20,
      difficulty: "Facile"
    )
  end
end
