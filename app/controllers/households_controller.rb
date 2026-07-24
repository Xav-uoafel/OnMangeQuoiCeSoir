class HouseholdsController < ApplicationController
  before_action :authenticate_user!

  def show
    @household = current_user.household

    unless @household
      redirect_to edit_household_path
      return
    end

    @members = @household.users
  end

  def edit
    @household = current_user.household || Household.new
  end

  def create
    @household = Household.new(household_params)

    if @household.save
      current_user.update!(household: @household, household_role: 'admin')
      redirect_to household_path, notice: "Foyer créé ! Code d’invitation : #{@household.invite_code}"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def update
    @household = current_user.household

    unless current_user.household_admin?
      redirect_to household_path, alert: 'Seul l\'admin peut modifier le foyer.'
      return
    end

    if @household.update(household_params)
      redirect_to household_path, notice: 'Foyer mis à jour.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def join
    @household = Household.find_by(invite_code: params[:invite_code]&.strip&.upcase)

    if @household
      current_user.update!(household: @household, household_role: 'member')
      redirect_to household_path, notice: "Vous avez rejoint le foyer \"#{@household.name}\" !"
    else
      redirect_to edit_household_path, alert: 'Code d\'invitation invalide.'
    end
  end

  private

  def household_params
    params.require(:household).permit(:name)
  end
end
