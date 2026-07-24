class ShoppingListItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shopping_list_item

  def update
    if @shopping_list_item.update(shopping_list_item_params)
      redirect_to plan_shopping_list_path(@plan), notice: "Liste mise a jour."
    else
      redirect_to plan_shopping_list_path(@plan), alert: @shopping_list_item.errors.full_messages.to_sentence
    end
  end

  private

  def set_shopping_list_item
    @plan = current_user.plans.find(params[:plan_id])
    @shopping_list = @plan.shopping_list || ShoppingListGenerator.new(@plan).generate
    @shopping_list_item = @shopping_list.shopping_list_items.find(params[:id])
  end

  def shopping_list_item_params
    params.require(:shopping_list_item).permit(:checked)
  end
end
