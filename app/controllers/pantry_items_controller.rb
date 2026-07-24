class PantryItemsController < ApplicationController
  before_action :authenticate_user!

  def index
    @pantry_items = current_user.pantry_items.recent
    @items_by_category = @pantry_items.group_by(&:category)
    @duplicate_count = duplicate_count
  end

  def create
    @pantry_item = PantryStockReconciler.new(current_user).upsert!(
      pantry_item_params.merge(source: 'manual', detected_on: Date.current)
    )

    redirect_to pantry_items_path, notice: "Ajout au stock : #{@pantry_item.name}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to pantry_items_path, alert: e.record.errors.full_messages.to_sentence
  end

  def update
    @pantry_item = current_user.pantry_items.find(params[:id])

    if @pantry_item.update(pantry_item_params)
      redirect_to pantry_items_path, notice: 'Ingrédient mis à jour.'
    else
      redirect_to pantry_items_path, alert: @pantry_item.errors.full_messages.to_sentence
    end
  end

  def destroy
    @pantry_item = current_user.pantry_items.find(params[:id])
    @pantry_item.destroy
    redirect_to pantry_items_path, notice: "Retrait du stock : #{@pantry_item.name}."
  end

  def merge_duplicates
    merged_count = PantryStockReconciler.new(current_user).merge_duplicates!

    if merged_count.positive?
      redirect_to pantry_items_path, notice: "#{merged_count} doublon(s) fusionne(s)."
    else
      redirect_to pantry_items_path, notice: "Aucun doublon à fusionner."
    end
  end

  private

  def pantry_item_params
    params.require(:pantry_item).permit(:name, :category, :quantity_text)
  end

  def duplicate_count
    current_user.pantry_items.to_a
                .group_by { |item| IngredientParser.canonical_name(item.name) }
                .sum { |canonical, items| canonical.present? && items.size > 1 ? items.size - 1 : 0 }
  end
end
