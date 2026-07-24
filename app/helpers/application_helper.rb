module ApplicationHelper
  CATEGORY_LABELS = {
    "legume" => "Légumes",
    "fruit" => "Fruits",
    "viande" => "Viandes",
    "poisson" => "Poissons",
    "produit_laitier" => "Produits laitiers",
    "epicerie" => "Épicerie",
    "condiment" => "Condiments",
    "boisson" => "Boissons",
    "autre" => "Autres"
  }.freeze

  DIETARY_RESTRICTION_LABELS = {
    "vegetarien" => "Végétarien",
    "vegetalien" => "Végétalien",
    "sans_gluten" => "Sans gluten",
    "sans_lactose" => "Sans lactose",
    "halal" => "Halal",
    "casher" => "Casher"
  }.freeze

  def ingredient_label(ingredient)
    item = ingredient.respond_to?(:symbolize_keys) ? ingredient.symbolize_keys : IngredientParser.parse_line(ingredient)
    quantity = item[:quantity]
    amount = quantity.present? ? format_ingredient_amount(quantity) : nil

    [amount, item[:unit].presence, item[:name]].compact.join(" ")
  end

  def ingredient_category_label(category)
    CATEGORY_LABELS.fetch(category.to_s, category.to_s.humanize)
  end

  def dietary_restriction_label(restriction)
    DIETARY_RESTRICTION_LABELS.fetch(restriction.to_s, restriction.to_s.humanize)
  end

  def recipe_ingredient_breakdown?(recipe)
    recipe.ingredients_from_pantry.present? || recipe.ingredients_to_buy.present?
  end

  def format_ingredient_amount(amount)
    number = amount.to_f
    number.to_i == number ? number.to_i : number.round(2)
  end

  def format_estimated_price(cents)
    return "Non estimé" if cents.nil?

    number_to_currency(
      cents.to_i / 100.0,
      unit: "€",
      separator: ",",
      delimiter: " ",
      format: "%n %u"
    )
  end

  def shopping_price_source_label(item)
    item.observed_price? ? "Relevé récent" : "Barème indicatif"
  end

  def shopping_unit_price_label(item)
    return if item.estimated_unit_price_cents.nil? || item.price_unit.blank?

    "#{format_estimated_price(item.estimated_unit_price_cents)}/#{item.price_unit}"
  end

  def recipe_cost_estimate_cents(recipe)
    RecipeCostEstimator.new(recipe).estimate_cents
  rescue StandardError => e
    Rails.logger.warn "Recipe cost estimate failed for recipe #{recipe.id}: #{e.class}"
    nil
  end

  def mobile_nav_item_class(section)
    classes = ["mobile-bottom-nav-item"]
    classes << "mobile-bottom-nav-item-active" if mobile_nav_active?(section)
    classes.join(" ")
  end

  def mobile_nav_aria_current(section)
    mobile_nav_active?(section) ? "page" : nil
  end

  def mobile_nav_active?(section)
    case section
    when :plan
      controller_name.in?(%w[plans shopping_lists shopping_list_items])
    when :stock
      controller_name == "pantry_items"
    when :scan
      controller_name == "pantry_scans"
    when :profile
      controller_name.in?(%w[profiles households onboardings])
    else
      false
    end
  end
end
