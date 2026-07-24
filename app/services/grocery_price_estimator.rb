# frozen_string_literal: true

class GroceryPriceEstimator
  def initialize(shopping_list, open_prices: Pricing::OpenPricesClient.new, catalog: Pricing::ReferenceCatalog.new)
    @shopping_list = shopping_list
    @open_prices = open_prices
    @catalog = catalog
  end

  def estimate
    estimates = @shopping_list.shopping_list_items.map do |item|
      [item, estimate_item(item)]
    end

    ShoppingListItem.transaction do
      estimates.each { |item, attributes| item.update!(attributes) }
      @shopping_list.update!(
        price_estimation_status: estimation_status(estimates),
        prices_estimated_at: Time.current
      )
    end

    @shopping_list
  end

  private

  def estimate_item(item)
    normalize_legacy_quantity(item)
    entry = @catalog.entry_for(item.name)
    quote = if entry
      @open_prices.quote_for(
        category_tag: entry[:category_tag],
        preferred_price_units: @catalog.preferred_price_units(item, entry)
      )
    end

    @catalog.estimate(item, entry: entry, quote: quote)
  rescue StandardError => e
    Rails.logger.warn "Price estimate fallback for item #{item.id}: #{e.class}"
    @catalog.estimate(item, entry: entry)
  end

  def normalize_legacy_quantity(item)
    return if item.quantity_value.present? || item.quantity_text.blank?
    return unless item.quantity_text.match?(/\A\d/)

    parsed = IngredientParser.parse_line("#{item.quantity_text} #{item.name}")
    quantity, unit = IngredientParser.canonical_quantity(parsed[:quantity], parsed[:unit])
    unit ||= "piece" if item.quantity_text.match?(/\A\d+(?:[.,]\d+)?\z/)

    item.assign_attributes(quantity_value: quantity, quantity_unit: unit)
  end

  def estimation_status(estimates)
    priced_count = estimates.count { |_item, attributes| attributes[:estimated_price_cents].present? }
    return "failed" if priced_count.zero? && estimates.any?
    return "partial" if priced_count < estimates.size

    "estimated"
  end
end
