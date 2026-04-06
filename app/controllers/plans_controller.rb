class PlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan, only: [:show, :generate, :destroy]

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
    @plans = current_user.plans.order(created_at: :desc)
  end

  def show
  end

  def new
    @plan = current_user.plans.build
    @default_constraints = {
      servings: current_user.household_size,
      max_preparation_time: current_user.preferred_max_prep_time,
      dietary_restrictions: current_user.dietary_restrictions || [],
      excluded_ingredients: current_user.excluded_ingredients || []
    }
  end

  def create
    @plan = current_user.plans.build(plan_params)

    if @plan.save
      @plan.update!(status: 'generating')
      RecipeGenerationJob.perform_later(@plan.id)
      redirect_to @plan, notice: 'Plan créé ! Génération des recettes en cours...'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def generate
    @plan.plan_recipes.destroy_all
    @plan.update!(status: 'generating')
    RecipeGenerationJob.perform_later(@plan.id)
    redirect_to @plan, notice: 'Régénération des recettes en cours...'
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
      excluded_ingredients: excluded_ingredients
    }
    
    # Ajouter les contraintes aux paramètres de base
    base_params[:constraints] = constraints
    
    base_params
  end
end 