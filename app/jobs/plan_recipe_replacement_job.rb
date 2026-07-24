class PlanRecipeReplacementJob < ApplicationJob
  queue_as :default

  def perform(plan_recipe_id)
    plan_recipe = PlanRecipe.find_by(id: plan_recipe_id)
    return unless plan_recipe&.replacement_generating?

    generator = RecipeGeneratorService.new(plan_recipe.plan)
    status = generator.replace(plan_recipe) ? "ready" : "failed"
    plan_recipe.update!(replacement_status: status)
    broadcast_recipe_update(plan_recipe)
  rescue StandardError => e
    Rails.logger.error "PlanRecipeReplacementJob failed for plan recipe #{plan_recipe_id}: #{e.class} - #{e.message}"
    Rails.error.report(e, handled: true)
    plan_recipe&.update!(replacement_status: "failed")
    broadcast_recipe_update(plan_recipe) if plan_recipe&.persisted?
  end

  private

  def broadcast_recipe_update(plan_recipe)
    Turbo::StreamsChannel.broadcast_replace_to(
      "plan_#{plan_recipe.plan_id}",
      target: "plan_recipe_#{plan_recipe.id}",
      partial: "plans/recipe",
      locals: { plan_recipe: plan_recipe }
    )
  rescue StandardError => e
    Rails.logger.error "PlanRecipeReplacementJob broadcast failed for plan recipe #{plan_recipe.id}: #{e.class} - #{e.message}"
  end
end
