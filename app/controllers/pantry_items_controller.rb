class PantryItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pantry_items = current_user.pantry_items.recent
    @items_by_category = @pantry_items.group_by(&:category)
  end

  def create
    @pantry_item = current_user.pantry_items.build(pantry_item_params)
    @pantry_item.source = 'manual'
    @pantry_item.detected_on = Date.current

    if @pantry_item.save
      redirect_to pantry_items_path, notice: "#{@pantry_item.name} ajoute au stock."
    else
      redirect_to pantry_items_path, alert: @pantry_item.errors.full_messages.to_sentence
    end
  end

  def update
    @pantry_item = current_user.pantry_items.find(params[:id])

    if @pantry_item.update(pantry_item_params)
      redirect_to pantry_items_path, notice: 'Ingredient mis a jour.'
    else
      redirect_to pantry_items_path, alert: @pantry_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @pantry_item = current_user.pantry_items.find(params[:id])
    @pantry_item.destroy
    redirect_to pantry_items_path, notice: "#{@pantry_item.name} retire du stock."
  end

  private

  def pantry_item_params
    params.require(:pantry_item).permit(:name, :category, :quantity_text)
  end
end
