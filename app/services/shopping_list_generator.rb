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
        category: item[:category]
      )
    end

    shopping_list
  end

  private

  def collect_ingredients_to_buy
    @plan.recipes.flat_map do |recipe|
      if recipe.ingredients_to_buy.present?
        recipe.ingredients_to_buy.map { |name| { name: name, recipe_title: recipe.title } }
      else
        parse_ingredients_from_text(recipe)
      end
    end
  end

  def parse_ingredients_from_text(recipe)
    recipe.ingredients.split(/[\n,]/).map(&:strip).reject(&:blank?).map do |line|
      { name: line, recipe_title: recipe.title }
    end
  end

  def group_and_deduplicate(items)
    items.group_by { |i| normalize_name(i[:name]) }.map do |_key, group|
      {
        name: group.first[:name],
        quantity_text: group.size > 1 ? "x#{group.size} (#{group.map { |g| g[:recipe_title] }.uniq.join(', ')})" : nil,
        category: guess_category(group.first[:name])
      }
    end
  end

  def normalize_name(name)
    name.downcase.gsub(/\d+\s*(g|kg|ml|l|cl)\b/, '').strip
  end

  def guess_category(name)
    name_lower = name.downcase
    return 'legume' if SeasonalIngredientsService.current[:vegetables].any? { |v| name_lower.include?(v.downcase) }
    return 'fruit' if SeasonalIngredientsService.current[:fruits].any? { |f| name_lower.include?(f.downcase) }

    'autre'
  end
end
