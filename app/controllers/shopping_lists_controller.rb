class ShoppingListsController < ApplicationController
  before_action :authenticate_user!
  database_rate_limit to: 12, within: 1.hour, scope: "price_refresh", only: :refresh_prices
  before_action :set_plan
  before_action :ensure_generated_plan

  def show
    generator = ShoppingListGenerator.new(@plan)
    @shopping_list = generator.generate
    @items_by_category = @shopping_list.items_by_category

    enqueue_price_estimation if @shopping_list.price_estimation_pending?
  end

  def refresh_prices
    @shopping_list = ShoppingListGenerator.new(@plan).generate
    if @shopping_list.price_estimation_in_progress?
      redirect_to plan_shopping_list_path(@plan), notice: "L'actualisation des prix est déjà en cours."
      return
    end

    @shopping_list.update!(price_estimation_status: "pending")

    if enqueue_price_estimation(force_refresh: true)
      redirect_to plan_shopping_list_path(@plan), notice: "Actualisation des prix lancée."
    else
      redirect_to plan_shopping_list_path(@plan), alert: "L’actualisation n’a pas pu démarrer. Vous pouvez réessayer."
    end
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def ensure_generated_plan
    return if @plan.generated?

    redirect_to @plan, alert: "Le plan doit être généré avant de créer une liste de courses."
  end

  def enqueue_price_estimation(force_refresh: false)
    job = ShoppingListPriceEstimationJob.perform_later(@shopping_list.id, force_refresh)
    return true if job.successfully_enqueued?

    @shopping_list.update!(price_estimation_status: "failed")
    false
  rescue ActiveJob::EnqueueError => e
    Rails.error.report(e, handled: true)
    @shopping_list.update!(price_estimation_status: "failed")
    false
  end
end
