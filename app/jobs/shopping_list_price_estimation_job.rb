class ShoppingListPriceEstimationJob < ApplicationJob
  queue_as :default

  def perform(shopping_list_id, force_refresh = false)
    shopping_list = ShoppingList.find(shopping_list_id)
    return unless start_estimation(shopping_list)

    broadcast_update(shopping_list)
    open_prices = Pricing::OpenPricesClient.new(force_refresh: force_refresh)
    GroceryPriceEstimator.new(shopping_list, open_prices: open_prices).estimate
    broadcast_update(shopping_list.reload)
  rescue StandardError => e
    Rails.logger.error "ShoppingListPriceEstimationJob failed for list #{shopping_list_id}: #{e.class} - #{e.message}"
    Rails.error.report(e, handled: true)
    shopping_list&.update!(price_estimation_status: "failed")
    broadcast_update(shopping_list) if shopping_list
  end

  private

  def start_estimation(shopping_list)
    shopping_list.with_lock do
      return false unless shopping_list.price_estimation_status.in?(%w[pending failed])

      shopping_list.update!(price_estimation_status: "estimating")
      true
    end
  end

  def broadcast_update(shopping_list)
    Turbo::StreamsChannel.broadcast_replace_to(
      "shopping_list_#{shopping_list.id}",
      target: "shopping_list_content",
      partial: "shopping_lists/content",
      locals: {
        plan: shopping_list.plan,
        shopping_list: shopping_list,
        items_by_category: shopping_list.items_by_category
      }
    )
  rescue StandardError => e
    Rails.logger.error "Shopping list price broadcast failed for list #{shopping_list.id}: #{e.class} - #{e.message}"
  end
end
