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
  end

  def create
    @plan = current_user.plans.build(plan_params)
    
    if @plan.save
      generator = RecipeGeneratorService.new(@plan)
      
      if generator.generate
        redirect_to @plan, notice: 'Plan créé et recettes générées avec succès !'
      else
        redirect_to @plan, alert: 'Le plan a été créé mais une erreur est survenue lors de la génération des recettes.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def generate
    generator = RecipeGeneratorService.new(@plan)
    
    if generator.generate
      redirect_to @plan, notice: 'Les recettes ont été générées avec succès !'
    else
      redirect_to @plan, alert: 'Une erreur est survenue lors de la génération des recettes.'
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
    constraints = {
      servings: params[:plan][:constraints_servings].presence&.to_i,
      max_preparation_time: params[:plan][:constraints_max_preparation_time].presence&.to_i,
      dietary_restrictions: [],
      excluded_ingredients: params[:plan][:constraints_excluded_ingredients].to_s.split(',').map(&:strip)
    }

    ["vegetarien", "vegetalien", "sans-gluten", "sans-lactose"].each do |restriction|
      if params[:plan]["constraints_dietary_restrictions_#{restriction}"] == "1"
        constraints[:dietary_restrictions] << restriction
      end
    end
    permitted_params = params.require(:plan).permit(
      :start_date, 
      :end_date,
      :weekday_lunches,
      :weekday_dinners,
      :weekend_lunches,
      :weekend_dinners,
      :constraints_servings,
      :constraints_max_preparation_time,
      :constraints_excluded_ingredients,
      :constraints_dietary_restrictions_vegetarien,
      :constraints_dietary_restrictions_vegetalien,
      :constraints_dietary_restrictions_sans_gluten,
      :constraints_dietary_restrictions_sans_lactose
    )

    permitted_params.merge(constraints: constraints)
  end
end 