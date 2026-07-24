class ShoppingListGenerator
  def initialize(plan)
    @plan = plan
    @user = plan.user
  end

  def generate
    return @plan.shopping_list if @plan.shopping_list.present?

    shopping_list = @plan.create_shopping_list!(user: @user)

    all_ingredients_to_buy = collect_ingredients_to_buy
    grouped = group_and_deduplicate(all_ingredients_to_buy)

    grouped.each do |item|
      shopping_list.shopping_list_items.create!(
        name: item[:name],
        quantity_text: item[:quantity_text],
        quantity_value: item[:canonical_quantity],
        quantity_unit: item[:canonical_unit],
        category: item[:category]
      )
    end

    shopping_list
  end

  private

  def collect_ingredients_to_buy
    @plan.recipes.flat_map do |recipe|
      split_recipe_ingredients(recipe)
      recipe.ingredients_to_buy.map do |ingredient|
        ingredient.symbolize_keys.merge(recipe_title: recipe.title)
      end
    end
  end

  def split_recipe_ingredients(recipe)
    pantry_names = @user.household_pantry_items.pluck(:name).map { |name| canonical_name(name) }.uniq
    from_pantry = []
    to_buy = []

    recipe.structured_ingredients.each do |ingredient|
      normalized = ingredient.symbolize_keys
      target = pantry_names.include?(canonical_name(normalized[:name])) ? from_pantry : to_buy
      target << normalized
    end

    recipe.update_columns(
      ingredients_from_pantry: from_pantry,
      ingredients_to_buy: to_buy
    )
  end

  def group_and_deduplicate(items)
    normalized_items = items.map { |item| normalize_item(item) }

    normalized_items.group_by { |i| [i[:canonical_name], i[:canonical_unit].to_s] }.map do |_key, group|
      quantity_text = combined_quantity_text(group)

      {
        name: group.first[:name],
        quantity_text: quantity_text,
        canonical_quantity: group.all? { |item| item[:canonical_quantity].present? } ? group.sum { |item| item[:canonical_quantity].to_f } : nil,
        canonical_unit: group.first[:canonical_unit],
        category: group.first[:category] || guess_category(group.first[:name])
      }
    end
  end

  def combined_quantity_text(group)
    return recipe_reference_text(group) if group.any? { |item| item[:canonical_quantity].blank? }

    total = group.sum { |item| item[:canonical_quantity].to_f }
    amount, unit = display_quantity(total, group.first[:canonical_unit])

    [amount, unit.presence].compact.join(" ")
  end

  def recipe_reference_text(group)
    references = group.map { |g| g[:recipe_title] }.uniq.join(", ")
    "x#{group.size} (#{references})"
  end

  def canonical_name(name)
    IngredientParser.canonical_name(name)
  end

  def normalize_item(item)
    normalized = item.symbolize_keys
    quantity, unit = IngredientParser.canonical_quantity(normalized[:quantity], normalized[:unit])

    normalized.merge(
      canonical_name: canonical_name(normalized[:name]),
      canonical_quantity: quantity,
      canonical_unit: unit
    )
  end

  def display_quantity(quantity, unit)
    amount = quantity.to_f

    case unit
    when "g"
      amount >= 1_000 ? [format_amount(amount / 1_000), "kg"] : [format_amount(amount), "g"]
    when "ml"
      amount >= 1_000 ? [format_amount(amount / 1_000), "l"] : [format_amount(amount), "ml"]
    else
      [format_amount(amount), unit]
    end
  end

  def format_amount(amount)
    rounded = amount.to_f.round(2)
    rounded.to_i == rounded ? rounded.to_i : rounded
  end

  def guess_category(name)
    IngredientParser.guess_category(name)
  end
end
