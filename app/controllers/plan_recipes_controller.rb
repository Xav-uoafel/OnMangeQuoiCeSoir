class PlanRecipesController < ApplicationController
  before_action :authenticate_user!
  database_rate_limit to: 20, within: 1.hour, scope: "recipe_replacement", only: :replace
  before_action :set_plan
  before_action :set_plan_recipe
  before_action :ensure_generated_plan

  def toggle_lock
    @plan_recipe.update!(locked: !@plan_recipe.locked?)
    respond_with_recipe
  end

  def replace
    if @plan_recipe.locked?
      redirect_to @plan, alert: "Déverrouillez ce repas avant de le remplacer."
      return
    end

    unless @plan_recipe.replacement_generating?
      @plan_recipe.update!(replacement_status: "generating")
      enqueue_replacement
    end

    respond_with_recipe
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def set_plan_recipe
    @plan_recipe = @plan.plan_recipes.find(params[:id])
  end

  def ensure_generated_plan
    return if @plan.generated?

    redirect_to @plan, alert: "Attendez la fin de la génération du plan."
  end

  def enqueue_replacement
    job = PlanRecipeReplacementJob.perform_later(@plan_recipe.id)
    return true if job.successfully_enqueued?

    @plan_recipe.update!(replacement_status: "failed")
    false
  rescue ActiveJob::EnqueueError => e
    Rails.error.report(e, handled: true)
    @plan_recipe.update!(replacement_status: "failed")
    false
  end

  def respond_with_recipe
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @plan_recipe,
          partial: "plans/recipe",
          locals: { plan_recipe: @plan_recipe }
        )
      end
      format.html { redirect_to plan_path(@plan, anchor: "plan_recipe_#{@plan_recipe.id}") }
    end
  end
end
