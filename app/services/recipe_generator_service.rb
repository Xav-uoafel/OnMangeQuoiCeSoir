class RecipeGeneratorService
  MAX_ATTEMPTS_PER_MEAL = 3
  DIVERSITY_IGNORED_INGREDIENTS = %w[sel poivre huile eau beurre ail oignon].freeze

  def initialize(plan, recipe_generator: nil, fallback_generator: nil)
    @plan = plan
    @user = plan.user
    @constraints = @plan.constraints.deep_symbolize_keys
    @constraints[:target_cost_per_meal_cents] ||= @plan.target_cost_per_meal_cents
    user_context = build_user_context
    @fallback_generator = fallback_generator || LocalRecipeGenerator.new(
      @constraints,
      user_context: user_context
    )
    @fallback_used = false
    @recipe_generator = recipe_generator || primary_generator(user_context)
  end

  def fallback_used?
    @fallback_used
  end

  def generate
    ActiveRecord::Base.transaction do
      generated_signatures = @plan.recipes.map { |recipe| recipe_signature(recipe) }

      missing_meal_slots.each do |date, meal_type|
        generate_recipe_for_meal(date, meal_type, generated_signatures)
      end
    end
    true
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la génération du plan : #{e.class} - #{e.message}"
    false
  end

  def replace(plan_recipe)
    raise ArgumentError, "Ce repas n'appartient pas au plan" unless plan_recipe.plan_id == @plan.id

    ActiveRecord::Base.transaction do
      generated_signatures = @plan.plan_recipes
                                  .where.not(id: plan_recipe.id)
                                  .includes(:recipe)
                                  .map { |entry| recipe_signature(entry.recipe) }
      recipe = generate_diverse_recipe(generated_signatures)
      recipe.user = @user
      recipe.save!

      plan_recipe.update!(recipe: recipe)
      @plan.shopping_list&.destroy!
    end
    true
  rescue StandardError => e
    Rails.logger.error "Erreur lors du remplacement d'un repas : #{e.class} - #{e.message}"
    false
  end

  private

  def build_user_context
    context = {}

    liked = @user.liked_recipes(5)
    context[:liked_recipes] = liked.map(&:title) if liked.any?

    disliked = @user.disliked_recipes(5)
    context[:disliked_recipes] = disliked.map(&:title) if disliked.any?

    pantry = @user.household_pantry_items
    context[:available_ingredients] = pantry.pluck(:name) if pantry.any?

    context
  end

  def missing_meal_slots
    occupied_slots = @plan.plan_recipes.pluck(:scheduled_for, :meal_type).index_with(true)
    @plan.meal_slots.reject { |slot| occupied_slots.key?(slot) }
  end

  def generate_recipe_for_meal(date, meal_type, generated_signatures)
    recipe = generate_diverse_recipe(generated_signatures)
    recipe.user = @user

    if recipe.save
      @plan.plan_recipes.create!(
        recipe: recipe,
        scheduled_for: date,
        meal_type: meal_type
      )
      generated_signatures << recipe_signature(recipe)
    else
      raise "Erreur lors de la sauvegarde de la recette : #{recipe.errors.full_messages.join(', ')}"
    end
  end

  def generate_diverse_recipe(generated_signatures)
    fallback_recipe = nil

    MAX_ATTEMPTS_PER_MEAL.times do
      recipe = next_recipe_candidate
      fallback_recipe ||= recipe

      return recipe unless duplicate_recipe?(recipe, generated_signatures)
    end

    Rails.logger.warn "Recette potentiellement répétitive conservée après #{MAX_ATTEMPTS_PER_MEAL} tentatives"
    fallback_recipe
  end

  def next_recipe_candidate
    @recipe_generator.generate_recipe
  rescue LLM::RecipeGenerator::GenerationError => e
    raise if @recipe_generator.equal?(@fallback_generator)

    @fallback_used = true
    Rails.logger.warn "Génération locale activée : #{e.code || e.class.name}"
    @recipe_generator = @fallback_generator
    @recipe_generator.generate_recipe
  end

  def primary_generator(user_context)
    unless ENV["OPENAI_API_KEY"].present?
      @fallback_used = true
      Rails.logger.warn "OPENAI_API_KEY absente : génération locale activée"
      return @fallback_generator
    end

    LLM::RecipeGenerator.new(@constraints, user_context: user_context)
  end

  def duplicate_recipe?(recipe, generated_signatures)
    signature = recipe_signature(recipe)

    generated_signatures.any? do |existing|
      existing[:title] == signature[:title] ||
        (existing[:ingredients] & signature[:ingredients]).size >= 2
    end
  end

  def recipe_signature(recipe)
    {
      title: IngredientParser.canonical_name(recipe.title),
      ingredients: main_ingredient_keys(recipe)
    }
  end

  def main_ingredient_keys(recipe)
    recipe.structured_ingredients
          .first(5)
          .map { |ingredient| IngredientParser.canonical_name(ingredient[:name] || ingredient["name"]) }
          .reject(&:blank?)
          .reject { |name| DIVERSITY_IGNORED_INGREDIENTS.include?(name) }
  end
end
