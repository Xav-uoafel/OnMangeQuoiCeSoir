# frozen_string_literal: true

class LocalRecipeGenerator
  def self.ingredient(name, quantity, unit, category)
    { name: name, quantity: quantity, unit: unit, category: category }
  end

  def self.template(title:, description:, preparation_time:, cooking_time:, tags:, ingredients:, instructions:)
    {
      title: title,
      description: description,
      preparation_time: preparation_time,
      cooking_time: cooking_time,
      tags: tags,
      ingredients: ingredients,
      instructions: instructions
    }
  end

  I = method(:ingredient)

  TEMPLATES = [
    template(
      title: "Curry de pois chiches et courgettes",
      description: "Un curry doux et crémeux, simple à préparer avec des ingrédients du placard.",
      preparation_time: 12,
      cooking_time: 22,
      tags: %i[vegan gluten_free],
      ingredients: [I.call("pois chiches", 120, "g", "epicerie"), I.call("courgette", 0.5, "piece", "legume"), I.call("tomate", 1, "piece", "legume"), I.call("lait de coco", 80, "ml", "epicerie"), I.call("curry", nil, nil, "condiment")],
      instructions: ["Couper la courgette et la tomate.", "Faire revenir les légumes avec le curry pendant 5 minutes.", "Ajouter les pois chiches et le lait de coco, puis mijoter 15 minutes.", "Rectifier l’assaisonnement et servir chaud."]
    ),
    template(
      title: "Riz sauté aux légumes et tofu",
      description: "Un plat complet et rapide qui valorise facilement les légumes disponibles.",
      preparation_time: 10,
      cooking_time: 18,
      tags: %i[vegan gluten_free],
      ingredients: [I.call("riz", 80, "g", "epicerie"), I.call("tofu", 90, "g", "autre"), I.call("carotte", 0.5, "piece", "legume"), I.call("courgette", 0.5, "piece", "legume"), I.call("sauce tamari", 10, "ml", "condiment")],
      instructions: ["Cuire le riz puis l’égoutter.", "Dorer le tofu en cubes dans une grande poêle.", "Ajouter les légumes émincés et cuire 8 minutes.", "Incorporer le riz et le tamari, puis faire sauter 3 minutes."]
    ),
    template(
      title: "Dahl de lentilles corail aux carottes",
      description: "Un dahl parfumé, économique et réconfortant, prêt en moins de trente minutes.",
      preparation_time: 10,
      cooking_time: 24,
      tags: %i[vegan gluten_free],
      ingredients: [I.call("lentilles corail", 85, "g", "epicerie"), I.call("carotte", 1, "piece", "legume"), I.call("tomate concassée", 100, "g", "epicerie"), I.call("lait de coco", 60, "ml", "epicerie"), I.call("cumin", nil, nil, "condiment")],
      instructions: ["Rincer les lentilles et couper les carottes en petits dés.", "Faire revenir les carottes avec le cumin pendant 3 minutes.", "Ajouter les lentilles, la tomate et un verre d’eau.", "Cuire 18 minutes puis incorporer le lait de coco."]
    ),
    template(
      title: "Quinoa aux légumes rôtis",
      description: "Une assiette colorée et légère avec des légumes fondants et du quinoa.",
      preparation_time: 15,
      cooking_time: 25,
      tags: %i[vegan gluten_free],
      ingredients: [I.call("quinoa", 75, "g", "epicerie"), I.call("aubergine", 0.5, "piece", "legume"), I.call("poivron", 0.5, "piece", "legume"), I.call("tomate", 1, "piece", "legume"), I.call("citron", 0.25, "piece", "fruit")],
      instructions: ["Préchauffer le four à 200 °C.", "Couper les légumes, les assaisonner et les rôtir 25 minutes.", "Cuire le quinoa selon les indications du paquet.", "Mélanger le tout avec le jus de citron."]
    ),
    template(
      title: "Pommes de terre et haricots verts au citron",
      description: "Une poêlée rustique et fraîche, relevée d’une sauce citronnée.",
      preparation_time: 15,
      cooking_time: 28,
      tags: %i[vegan gluten_free],
      ingredients: [I.call("pomme de terre", 220, "g", "legume"), I.call("haricots verts", 120, "g", "legume"), I.call("citron", 0.25, "piece", "fruit"), I.call("moutarde", 5, "g", "condiment"), I.call("persil", nil, nil, "condiment")],
      instructions: ["Cuire les pommes de terre en cubes dans l’eau salée.", "Ajouter les haricots verts pour les 8 dernières minutes.", "Mélanger le citron et la moutarde.", "Égoutter, poêler rapidement puis ajouter la sauce et le persil."]
    ),
    template(
      title: "Polenta crémeuse à la ratatouille",
      description: "Une polenta onctueuse accompagnée de légumes du soleil mijotés.",
      preparation_time: 15,
      cooking_time: 30,
      tags: %i[vegan gluten_free],
      ingredients: [I.call("polenta", 70, "g", "epicerie"), I.call("aubergine", 0.5, "piece", "legume"), I.call("courgette", 0.5, "piece", "legume"), I.call("tomate", 1, "piece", "legume"), I.call("herbes de Provence", nil, nil, "condiment")],
      instructions: ["Couper les légumes en dés et les faire revenir 5 minutes.", "Ajouter un fond d’eau et les herbes, puis mijoter 20 minutes.", "Cuire la polenta en remuant jusqu’à ce qu’elle soit crémeuse.", "Servir la ratatouille sur la polenta."]
    ),
    template(
      title: "Pâtes aux aubergines et tomates",
      description: "Des pâtes généreuses nappées d’une sauce tomate aux aubergines fondantes.",
      preparation_time: 12,
      cooking_time: 22,
      tags: %i[vegan],
      ingredients: [I.call("pâtes", 90, "g", "epicerie"), I.call("aubergine", 0.5, "piece", "legume"), I.call("tomate concassée", 120, "g", "epicerie"), I.call("ail", 0.5, "piece", "condiment"), I.call("basilic", nil, nil, "condiment")],
      instructions: ["Cuire les pâtes al dente.", "Dorer l’aubergine en dés avec l’ail.", "Ajouter la tomate et laisser mijoter 12 minutes.", "Mélanger avec les pâtes et terminer avec le basilic."]
    ),
    template(
      title: "Couscous de légumes aux pois chiches",
      description: "Un couscous végétal parfumé, riche en légumes et facile à partager.",
      preparation_time: 18,
      cooking_time: 30,
      tags: %i[vegan],
      ingredients: [I.call("semoule", 80, "g", "epicerie"), I.call("pois chiches", 90, "g", "epicerie"), I.call("carotte", 1, "piece", "legume"), I.call("courgette", 0.5, "piece", "legume"), I.call("ras el-hanout", nil, nil, "condiment")],
      instructions: ["Couper les légumes et les faire revenir avec les épices.", "Couvrir d’eau et laisser mijoter 20 minutes.", "Ajouter les pois chiches pour les 8 dernières minutes.", "Préparer la semoule et servir avec les légumes et leur bouillon."]
    ),
    template(
      title: "Omelette aux champignons et pommes de terre",
      description: "Une omelette complète et dorée, idéale pour un dîner rapide.",
      preparation_time: 10,
      cooking_time: 20,
      tags: %i[vegetarian gluten_free lactose_free],
      ingredients: [I.call("oeuf", 2, "piece", "autre"), I.call("champignon", 100, "g", "legume"), I.call("pomme de terre", 120, "g", "legume"), I.call("persil", nil, nil, "condiment"), I.call("paprika", nil, nil, "condiment")],
      instructions: ["Cuire les pommes de terre en petits cubes à la poêle.", "Ajouter les champignons et poursuivre 6 minutes.", "Battre les œufs avec le paprika et le persil.", "Verser dans la poêle et cuire l’omelette à feu doux."]
    ),
    template(
      title: "Poulet citron, carottes et riz",
      description: "Un poulet tendre au citron servi avec du riz et des carottes fondantes.",
      preparation_time: 15,
      cooking_time: 25,
      tags: %i[gluten_free lactose_free],
      ingredients: [I.call("filet de poulet", 150, "g", "viande"), I.call("riz", 70, "g", "epicerie"), I.call("carotte", 1, "piece", "legume"), I.call("citron", 0.25, "piece", "fruit"), I.call("thym", nil, nil, "condiment")],
      instructions: ["Cuire le riz.", "Dorer le poulet avec le thym.", "Ajouter les carottes émincées et un fond d’eau, puis couvrir 15 minutes.", "Ajouter le jus de citron et servir avec le riz."]
    ),
    template(
      title: "Saumon au fenouil et pommes vapeur",
      description: "Un plat de poisson simple, frais et équilibré avec une cuisson douce.",
      preparation_time: 15,
      cooking_time: 22,
      tags: %i[gluten_free lactose_free],
      ingredients: [I.call("saumon", 140, "g", "poisson"), I.call("fenouil", 0.5, "piece", "legume"), I.call("pomme de terre", 180, "g", "legume"), I.call("citron", 0.25, "piece", "fruit"), I.call("aneth", nil, nil, "condiment")],
      instructions: ["Cuire les pommes de terre à la vapeur.", "Émincer le fenouil et le faire fondre 10 minutes à couvert.", "Cuire le saumon à la poêle ou à la vapeur.", "Servir avec le citron et l’aneth."]
    ),
    template(
      title: "Gratin de courgettes à la ricotta",
      description: "Un gratin léger et fondant qui met les courgettes à l’honneur.",
      preparation_time: 15,
      cooking_time: 30,
      tags: %i[vegetarian gluten_free],
      ingredients: [I.call("courgette", 1, "piece", "legume"), I.call("ricotta", 70, "g", "produit_laitier"), I.call("oeuf", 0.5, "piece", "autre"), I.call("tomate", 0.5, "piece", "legume"), I.call("herbes de Provence", nil, nil, "condiment")],
      instructions: ["Préchauffer le four à 190 °C.", "Couper les courgettes et les tomates en fines rondelles.", "Mélanger la ricotta avec les œufs et les herbes.", "Assembler dans un plat et cuire 30 minutes."]
    )
  ].freeze

  SAFE_STAPLES = [
    I.call("riz", 80, "g", "epicerie"),
    I.call("quinoa", 75, "g", "epicerie"),
    I.call("pomme de terre", 200, "g", "legume"),
    I.call("lentilles corail", 85, "g", "epicerie")
  ].freeze

  def initialize(constraints, user_context: {})
    @constraints = constraints.to_h.deep_symbolize_keys
    @user_context = user_context.to_h.deep_symbolize_keys
    @servings = @constraints[:servings].presence&.to_i || 4
    @excluded = Array(@constraints[:excluded_ingredients]).map { |name| IngredientParser.canonical_name(name) }
    @index = 0
    @templates = select_templates
  end

  def generate_recipe
    template = @templates[@index % @templates.length]
    @index += 1
    build_recipe(template)
  end

  private

  def select_templates
    compatible = TEMPLATES.select { |template| compatible_with_restrictions?(template) }
    timed = compatible.select { |template| within_preparation_limit?(template) }
    timed = compatible if timed.empty?
    filtered = timed.reject { |template| template_conflicts_with_exclusions?(template) }
    filtered = [safe_template] if filtered.empty?

    prioritize_for_budget(prioritize_available_ingredients(filtered))
  end

  def compatible_with_restrictions?(template)
    restrictions = Array(@constraints[:dietary_restrictions]).map { |value| IngredientParser.canonical_name(value) }
    tags = template[:tags]

    return false if restrictions.include?("vegetalien") && !tags.include?(:vegan)
    return false if restrictions.include?("vegetarien") && (tags & %i[vegan vegetarian]).empty?
    return false if restrictions.include?("sans gluten") && !tags.include?(:gluten_free)
    return false if restrictions.include?("sans lactose") && !(tags & %i[vegan lactose_free]).any?
    return false if restrictions.intersect?(%w[halal casher]) && !tags.include?(:vegan)

    true
  end

  def within_preparation_limit?(template)
    limit = @constraints[:max_preparation_time].presence&.to_i
    limit.blank? || template[:preparation_time] <= limit
  end

  def template_conflicts_with_exclusions?(template)
    return false if @excluded.empty?

    title = IngredientParser.canonical_name(template[:title])
    return true if @excluded.any? { |excluded| title.include?(excluded) }

    template[:ingredients]
      .reject { |ingredient| ingredient[:category] == "condiment" }
      .any? { |ingredient| excluded_ingredient?(ingredient[:name]) }
  end

  def prioritize_available_ingredients(templates)
    available = Array(@user_context[:available_ingredients]).map { |name| IngredientParser.canonical_name(name) }
    return templates if available.empty?

    templates.sort_by do |template|
      matches = template[:ingredients].count do |ingredient|
        name = IngredientParser.canonical_name(ingredient[:name])
        available.any? { |pantry_name| pantry_name.include?(name) || name.include?(pantry_name) }
      end
      -matches
    end
  end

  def prioritize_for_budget(templates)
    target = @constraints[:target_cost_per_meal_cents].to_i
    return templates unless target.positive?

    templates.each_with_index.sort_by do |template, index|
      estimate = RecipeCostEstimator.new(build_recipe(template)).estimate_cents
      [estimate > target ? 1 : 0, (estimate - target).abs, index]
    end.map(&:first)
  end

  def safe_template
    staple = SAFE_STAPLES.find { |ingredient| !excluded_ingredient?(ingredient[:name]) } || SAFE_STAPLES.first
    vegetables = SeasonalIngredientsService.current[:vegetables]
      .reject { |name| excluded_ingredient?(name) }
      .first(3)
      .map { |name| self.class.ingredient(name, 0.5, "piece", "legume") }
    vegetables = [self.class.ingredient("légumes de saison", 180, "g", "legume")] if vegetables.empty?

    self.class.template(
      title: "Poêlée de saison au #{staple[:name]}",
      description: "Une poêlée végétale adaptable aux ingrédients disponibles et aux exclusions indiquées.",
      preparation_time: [@constraints[:max_preparation_time].presence&.to_i || 10, 10].min,
      cooking_time: 20,
      tags: %i[vegan gluten_free],
      ingredients: [staple, *vegetables],
      instructions: ["Préparer et couper les légumes.", "Cuire la base selon les indications du paquet.", "Faire revenir les légumes jusqu’à ce qu’ils soient tendres.", "Mélanger, assaisonner et servir chaud."]
    )
  end

  def excluded_ingredient?(name)
    canonical = IngredientParser.canonical_name(name)
    @excluded.any? { |excluded| canonical.include?(excluded) || excluded.include?(canonical) }
  end

  def build_recipe(template)
    ingredients = template[:ingredients].reject { |ingredient| excluded_ingredient?(ingredient[:name]) }
    structured = ingredients.map { |ingredient| scale_ingredient(ingredient) }

    Recipe.new(
      title: template[:title],
      description: template[:description],
      ingredients: structured.map { |ingredient| ingredient[:raw] }.join("\n"),
      instructions: template[:instructions].each_with_index.map { |step, index| "#{index + 1}. #{step}" }.join("\n"),
      servings: @servings,
      preparation_time: template[:preparation_time],
      cooking_time: template[:cooking_time],
      difficulty: "Facile",
      seasonal_ingredients_used: seasonal_ingredients_used(ingredients),
      recipe_ingredients: structured,
      generated_at: Time.current
    )
  end

  def scale_ingredient(ingredient)
    quantity = ingredient[:quantity]&.*(@servings)
    unit = ingredient[:unit]
    name = ingredient[:name]
    raw = if quantity.nil?
      name
    elsif unit == "piece"
      "#{format_quantity(quantity)} #{name}"
    else
      "#{format_quantity(quantity)} #{unit} de #{name}"
    end

    ingredient.merge(raw: raw, quantity: quantity)
  end

  def format_quantity(quantity)
    quantity.to_i == quantity ? quantity.to_i : quantity.round(1)
  end

  def seasonal_ingredients_used(ingredients)
    seasonal = SeasonalIngredientsService.current.values.flatten
    ingredient_names = ingredients.map { |ingredient| IngredientParser.canonical_name(ingredient[:name]) }

    seasonal.select do |seasonal_name|
      canonical = IngredientParser.canonical_name(seasonal_name)
      ingredient_names.any? { |name| name.include?(canonical) || canonical.include?(name) }
    end.uniq
  end
end
