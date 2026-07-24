class IngredientParser
  UNITS = %w[g kg ml cl l cuillère cuillères càs cas càc cac piece pieces tranche tranches botte bottes sachet sachets].freeze
  UNIT_ALIASES = {
    "cuillères" => "cuillère",
    "pieces" => "piece",
    "tranches" => "tranche",
    "bottes" => "botte",
    "sachets" => "sachet"
  }.freeze

  CONVERTIBLE_UNITS = {
    "g" => ["g", 1],
    "kg" => ["g", 1_000],
    "ml" => ["ml", 1],
    "cl" => ["ml", 10],
    "l" => ["ml", 1_000]
  }.freeze

  CATEGORY_KEYWORDS = {
    "viande" => %w[boeuf bœuf poulet dinde porc jambon lardon steak veau canard agneau saucisse],
    "poisson" => %w[saumon thon cabillaud crevette moule poisson sardine truite],
    "produit_laitier" => %w[lait creme crème beurre yaourt fromage mozzarella parmesan],
    "epicerie" => %w[riz pates pâtes farine sucre sel poivre huile vinaigre bouillon lentilles pois chiches quinoa],
    "condiment" => %w[moutarde ketchup mayo mayonnaise sauce pesto curry paprika cumin],
    "boisson" => %w[eau jus soda vin bière biere]
  }.freeze

  def self.parse_lines(text)
    text.to_s.split(/\n/).filter_map do |line|
      parsed = parse_line(line)
      parsed if parsed[:name].present?
    end
  end

  def self.parse_line(line)
    raw = line.to_s.strip
    return empty_result if raw.blank?

    match = raw.match(/\A(?<quantity>\d+(?:[.,]\d+)?)\s*(?<unit>[[:alpha:]À-ÿ]+)?\s+(?<name>.+)\z/)

    if match
      quantity = match[:quantity].tr(",", ".").to_f
      unit = normalize_unit(match[:unit])
      name = normalize_name(match[:name])

      {
        raw: raw,
        quantity: quantity,
        unit: unit,
        name: name,
        category: guess_category(name)
      }
    else
      name = normalize_name(raw)
      {
        raw: raw,
        quantity: nil,
        unit: nil,
        name: name,
        category: guess_category(name)
      }
    end
  end

  def self.normalize_name(name)
    name.to_s.downcase.gsub(/\Ade\s+/, "").strip
  end

  def self.canonical_name(name)
    normalized = normalize_name(name)
    ascii = I18n.transliterate(normalized)
    words = ascii.gsub(/[’']/, " ")
                 .gsub(/[^a-z0-9\s-]/, " ")
                 .squish
                 .split
    words.shift while %w[d de du des la le les l].include?(words.first)

    words.map { |word| singularize_word(word) }.join(" ")
  end

  def self.normalize_unit(unit)
    normalized = unit.to_s.downcase.strip
    return nil if normalized.blank?

    return nil unless UNITS.include?(normalized)

    UNIT_ALIASES.fetch(normalized, normalized)
  end

  def self.canonical_quantity(quantity, unit)
    return [normalize_quantity(quantity), nil] if unit.blank?

    normalized_unit = normalize_unit(unit)
    normalized_quantity = normalize_quantity(quantity)
    return [nil, CONVERTIBLE_UNITS.fetch(normalized_unit, [normalized_unit]).first] if normalized_quantity.nil?
    return [normalized_quantity, normalized_unit] unless CONVERTIBLE_UNITS.key?(normalized_unit)

    canonical_unit, multiplier = CONVERTIBLE_UNITS.fetch(normalized_unit)
    [normalized_quantity * multiplier, canonical_unit]
  end

  def self.guess_category(name)
    lower_name = name.to_s.downcase
    return "legume" if SeasonalIngredientsService.current[:vegetables].any? { |v| lower_name.include?(v.downcase) }
    return "fruit" if SeasonalIngredientsService.current[:fruits].any? { |f| lower_name.include?(f.downcase) }

    CATEGORY_KEYWORDS.each do |category, keywords|
      return category if keywords.any? { |keyword| lower_name.include?(keyword) }
    end

    "autre"
  end

  def self.empty_result
    { raw: nil, quantity: nil, unit: nil, name: nil, category: "autre" }
  end

  def self.normalize_quantity(quantity)
    return nil if quantity.blank?

    quantity.to_f
  end

  def self.singularize_word(word)
    return word if word.length <= 3
    return word if word.end_with?("x", "z")

    word.end_with?("s") ? word.delete_suffix("s") : word
  end
  private_class_method :singularize_word
end
