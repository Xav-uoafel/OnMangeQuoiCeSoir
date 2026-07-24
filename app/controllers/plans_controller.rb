class PlansController < ApplicationController
  before_action :authenticate_user!
  database_rate_limit to: 8, within: 1.hour, scope: "plan_generation", only: %i[create generate]
  before_action :set_plan, only: [:show, :update, :generate, :destroy]

  def dashboard
    current_plan = current_user.plans
                              .where('end_date >= ?', Date.current)
                              .where(status: 'generated')
                              .order(created_at: :desc)
                              .first

    if current_plan
      redirect_to plan_path(current_plan)
    elsif current_user.plans.any?
      redirect_to plans_path
    else
      redirect_to new_plan_path
    end
  end

  def index
    @plans = current_user.plans.includes(:recipes).order(created_at: :desc)
  end

  def show
  end

  def new
    @plan = current_user.plans.build
    @default_constraints = default_constraints
  end

  def create
    @plan = current_user.plans.build(plan_params)

    if @plan.save
      if enqueue_generation(@plan)
        redirect_to @plan, notice: 'Plan créé ! Génération des recettes en cours...'
      else
        redirect_to @plan, alert: "Le plan est enregistré, mais la génération n'a pas pu démarrer."
      end
    else
      @default_constraints = default_constraints
      render :new, status: :unprocessable_content
    end
  end

  def generate
    @plan.shopping_list&.destroy!
    locked_count = @plan.plan_recipes.where(locked: true).count
    @plan.plan_recipes.where(locked: false).destroy_all
    if enqueue_generation(@plan)
      notice = if locked_count.positive?
        locked_label = locked_count == 1 ? "repas verrouillé conservé" : "repas verrouillés conservés"
        "Régénération en cours. #{locked_count} #{locked_label}."
      else
        'Régénération des recettes en cours...'
      end
      redirect_to @plan, notice: notice
    else
      redirect_to @plan, alert: "La régénération n'a pas pu démarrer. Réessayez dans quelques instants."
    end
  end

  def update
    budget_cents = weekly_budget_cents(params.dig(:plan, :weekly_budget))
    constraints = @plan.constraints.to_h.merge("weekly_budget_cents" => budget_cents)

    if @plan.update(constraints: constraints)
      redirect_to @plan, notice: budget_cents.present? ? "Budget hebdomadaire mis à jour." : "Budget hebdomadaire retiré."
    else
      flash.now[:alert] = "Le budget n'a pas pu être mis à jour."
      render :show, status: :unprocessable_content
    end
  end

  def destroy
    @plan.destroy
    redirect_to plans_path, notice: 'Plan supprimé avec succès.'
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:id])
  end

  def plan_params
    raw_params = params.require(:plan).permit(
      :start_date, :end_date, 
      :weekday_lunches, :weekday_dinners, 
      :weekend_lunches, :weekend_dinners,
      :constraints_servings, 
      :constraints_max_preparation_time,
      :constraints_weekly_budget,
      :constraints_dietary_restrictions_vegetarien,
      :constraints_dietary_restrictions_vegetalien,
      :constraints_dietary_restrictions_sans_gluten,
      :constraints_dietary_restrictions_sans_lactose,
      :constraints_excluded_ingredients
    )
    
    # Extraire les paramètres de base
    base_params = raw_params.slice(
      :start_date, :end_date, 
      :weekday_lunches, :weekday_dinners, 
      :weekend_lunches, :weekend_dinners
    )
    
    # Construire l'objet constraints
    dietary_restrictions = []
    dietary_restrictions << "vegetarien" if raw_params[:constraints_dietary_restrictions_vegetarien] == "1"
    dietary_restrictions << "vegetalien" if raw_params[:constraints_dietary_restrictions_vegetalien] == "1"
    dietary_restrictions << "sans_gluten" if raw_params[:constraints_dietary_restrictions_sans_gluten] == "1"
    dietary_restrictions << "sans_lactose" if raw_params[:constraints_dietary_restrictions_sans_lactose] == "1"
    
    excluded_ingredients = raw_params[:constraints_excluded_ingredients].to_s.split(",").map(&:strip).reject(&:blank?)
    
    constraints = {
      servings: raw_params[:constraints_servings].presence&.to_i,
      max_preparation_time: raw_params[:constraints_max_preparation_time].presence&.to_i,
      dietary_restrictions: dietary_restrictions,
      excluded_ingredients: excluded_ingredients,
      weekly_budget_cents: weekly_budget_cents(raw_params[:constraints_weekly_budget])
    }

    # Ajouter les contraintes aux paramètres de base
    base_params[:constraints] = constraints

    base_params
  end

  def weekly_budget_cents(value)
    return if value.blank?

    (BigDecimal(value.to_s.tr(",", ".")) * 100).round.to_i
  rescue ArgumentError, FloatDomainError
    -1
  end

  def default_constraints
    {
      servings: current_user.household_size,
      max_preparation_time: current_user.preferred_max_prep_time,
      dietary_restrictions: current_user.dietary_restrictions || [],
      excluded_ingredients: current_user.excluded_ingredients || [],
      weekly_budget: nil
    }
  end

  def enqueue_generation(plan)
    token = plan.start_generation!
    job = RecipeGenerationJob.perform_later(plan.id, token)
    return true if job.successfully_enqueued?

    plan.fail_generation!(token, code: "queue_unavailable")
    false
  rescue ActiveJob::EnqueueError => e
    Rails.error.report(e, handled: true)
    plan.fail_generation!(token, code: "queue_unavailable") if token
    false
  end
end
