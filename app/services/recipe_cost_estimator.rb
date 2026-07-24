# frozen_string_literal: true

class RecipeCostEstimator
  Item = Data.define(:name, :category, :quantity_value, :quantity_unit)

  def initialize(recipe, catalog: Pricing::ReferenceCatalog.new)
    @recipe = recipe
    @catalog = catalog
  end

  def estimate_cents
    @recipe.structured_ingredients.sum do |ingredient|
      estimate_ingredient(ingredient.symbolize_keys)
    end
  end

  private

  def estimate_ingredient(ingredient)
    quantity, unit = IngredientParser.canonical_quantity(ingredient[:quantity], ingredient[:unit])
    item = Item.new(
      name: ingredient[:name],
      category: ingredient[:category],
      quantity_value: quantity,
      quantity_unit: unit
    )

    @catalog.estimate(item).fetch(:estimated_price_cents, 0).to_i
  end
end
