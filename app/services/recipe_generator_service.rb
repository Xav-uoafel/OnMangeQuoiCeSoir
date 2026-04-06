class RecipeGeneratorService
  def initialize(plan)
    @plan = plan
    @user = plan.user
    @recipe_generator = LLM::RecipeGenerator.new(
      @plan.constraints.deep_symbolize_keys,
      user_context: build_user_context
    )
  end

  def generate
    ActiveRecord::Base.transaction do
      (@plan.start_date..@plan.end_date).each do |date|
        is_weekend = date.saturday? || date.sunday?

        if (is_weekend && @plan.weekend_lunches) || (!is_weekend && @plan.weekday_lunches)
          generate_recipe_for_meal(date, "Déjeuner")
        end

        if (is_weekend && @plan.weekend_dinners) || (!is_weekend && @plan.weekday_dinners)
          generate_recipe_for_meal(date, "Dîner")
        end
      end
    end
    true
  rescue StandardError => e
    Rails.logger.error "Erreur lors de la génération du plan : #{e.message}"
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

  def generate_recipe_for_meal(date, meal_type)
    recipe = @recipe_generator.generate_recipe
    recipe.user = @user

    if recipe.save
      @plan.plan_recipes.create!(
        recipe: recipe,
        scheduled_for: date,
        meal_type: meal_type
      )
    else
      raise "Erreur lors de la sauvegarde de la recette : #{recipe.errors.full_messages.join(', ')}"
    end
  end
end
