class ShoppingListsController < ApplicationController
  before_action :authenticate_user!

  def show
    @plan = current_user.plans.find(params[:plan_id])

    unless @plan.generated?
      redirect_to @plan, alert: 'Le plan doit etre genere avant de creer une liste de courses.'
      return
    end

    generator = ShoppingListGenerator.new(@plan)
    @shopping_list = generator.generate
    @items_by_category = @shopping_list.items_by_category
  end
end
