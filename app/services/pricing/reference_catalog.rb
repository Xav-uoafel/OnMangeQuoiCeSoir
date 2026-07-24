# frozen_string_literal: true

module Pricing
  class ReferenceCatalog
    REFERENCE_DATE = Date.new(2026, 7, 1)

    ENTRIES = [
      { names: ["courgette"], mode: :weight, unit_price_cents: 320, category_tag: "en:zucchini", piece_weight_g: 250, default_weight_g: 500 },
      { names: ["tomate"], mode: :weight, unit_price_cents: 299, category_tag: "en:tomatoes", piece_weight_g: 125, default_weight_g: 500 },
      { names: ["carotte"], mode: :weight, unit_price_cents: 199, category_tag: "en:carrots", piece_weight_g: 125, default_weight_g: 500 },
      { names: ["aubergine"], mode: :weight, unit_price_cents: 480, category_tag: "en:aubergines", piece_weight_g: 300, default_weight_g: 500 },
      { names: ["poivron"], mode: :weight, unit_price_cents: 509, category_tag: "en:peppers", piece_weight_g: 180, default_weight_g: 400 },
      { names: ["citron"], mode: :weight, unit_price_cents: 395, category_tag: "en:lemons", piece_weight_g: 120, default_weight_g: 250 },
      { names: ["pomme de terre", "pommes de terre"], mode: :weight, unit_price_cents: 299, category_tag: "en:potatoes", piece_weight_g: 180, default_weight_g: 1_000 },
      { names: ["haricot vert", "haricots verts"], mode: :weight, unit_price_cents: 450, category_tag: "en:green-beans", default_weight_g: 500 },
      { names: ["champignon", "champignons"], mode: :weight, unit_price_cents: 599, category_tag: "en:mushrooms", default_weight_g: 250 },
      { names: ["fenouil"], mode: :weight, unit_price_cents: 399, category_tag: "en:fennel-bulbs", piece_weight_g: 300, default_weight_g: 300 },
      { names: ["ail"], mode: :package, package_price_cents: 80, package_quantity: 6, package_unit: "piece" },
      { names: ["oignon"], mode: :weight, unit_price_cents: 299, category_tag: "en:onions", piece_weight_g: 120, default_weight_g: 500 },
      { names: ["concombre"], mode: :weight, unit_price_cents: 499, category_tag: "en:cucumbers", piece_weight_g: 350, default_weight_g: 350 },
      { names: ["filet de poulet", "poulet"], mode: :weight, unit_price_cents: 1_520, category_tag: "en:chicken-breasts", default_weight_g: 500 },
      { names: ["saumon"], mode: :weight, unit_price_cents: 2_200, category_tag: "en:salmon", default_weight_g: 300 },
      { names: ["riz"], mode: :package, package_price_cents: 220, package_quantity: 1_000, package_unit: "g" },
      { names: ["pâtes", "pates"], mode: :package, package_price_cents: 160, package_quantity: 500, package_unit: "g" },
      { names: ["pois chiches", "pois chiche"], mode: :package, package_price_cents: 125, package_quantity: 400, package_unit: "g" },
      { names: ["lentilles corail"], mode: :package, package_price_cents: 250, package_quantity: 500, package_unit: "g" },
      { names: ["quinoa"], mode: :package, package_price_cents: 450, package_quantity: 500, package_unit: "g" },
      { names: ["polenta"], mode: :package, package_price_cents: 210, package_quantity: 500, package_unit: "g" },
      { names: ["semoule"], mode: :package, package_price_cents: 190, package_quantity: 1_000, package_unit: "g" },
      { names: ["tofu"], mode: :package, package_price_cents: 300, package_quantity: 400, package_unit: "g" },
      { names: ["lait de coco"], mode: :package, package_price_cents: 190, package_quantity: 400, package_unit: "ml" },
      { names: ["tomate concassée", "tomate concassee"], mode: :package, package_price_cents: 120, package_quantity: 400, package_unit: "g" },
      { names: ["sauce tamari", "tamari"], mode: :package, package_price_cents: 390, package_quantity: 250, package_unit: "ml" },
      { names: ["moutarde"], mode: :package, package_price_cents: 150, package_quantity: 350, package_unit: "g" },
      { names: ["oeuf", "œuf", "oeufs", "œufs"], mode: :package, package_price_cents: 250, package_quantity: 6, package_unit: "piece" },
      { names: ["ricotta"], mode: :package, package_price_cents: 220, package_quantity: 250, package_unit: "g" },
      { names: ["curry", "cumin", "paprika", "ras el-hanout", "herbes de Provence"], mode: :package, package_price_cents: 180, package_quantity: 1, package_unit: "piece" },
      { names: ["persil", "basilic", "thym", "aneth"], mode: :unit, unit_price_cents: 120 }
    ].freeze

    CATEGORY_DEFAULTS = {
      "legume" => { mode: :weight, unit_price_cents: 350, default_weight_g: 500 },
      "fruit" => { mode: :weight, unit_price_cents: 350, default_weight_g: 500 },
      "viande" => { mode: :weight, unit_price_cents: 1_400, default_weight_g: 500 },
      "poisson" => { mode: :weight, unit_price_cents: 1_800, default_weight_g: 400 },
      "produit_laitier" => { mode: :package, package_price_cents: 250, package_quantity: 1, package_unit: "piece" },
      "epicerie" => { mode: :package, package_price_cents: 220, package_quantity: 1, package_unit: "piece" },
      "condiment" => { mode: :package, package_price_cents: 180, package_quantity: 1, package_unit: "piece" },
      "boisson" => { mode: :package, package_price_cents: 180, package_quantity: 1, package_unit: "piece" },
      "autre" => { mode: :package, package_price_cents: 250, package_quantity: 1, package_unit: "piece" }
    }.freeze

    def initialize
      @entries_by_name = ENTRIES.each_with_object({}) do |entry, index|
        entry[:names].each { |name| index[IngredientParser.canonical_name(name)] = entry }
      end
    end

    def entry_for(name)
      @entries_by_name[IngredientParser.canonical_name(name)]
    end

    def preferred_price_units(item, entry)
      return [] if entry.blank? || entry[:category_tag].blank?

      if item.quantity_unit == "piece"
        ["UNIT", "KILOGRAM"]
      elsif item.quantity_unit == "g" || entry[:mode] == :weight
        ["KILOGRAM"]
      else
        []
      end
    end

    def estimate(item, entry: nil, quote: nil)
      entry ||= entry_for(item.name)
      observed = estimate_from_quote(item, entry, quote) if entry && quote
      observed || estimate_from_reference(item, entry)
    end

    private

    def estimate_from_quote(item, entry, quote)
      unit_price_cents = quote.fetch(:unit_price_cents)

      amount_cents = case quote.fetch(:price_per)
      when "KILOGRAM"
        weight = weight_in_kilograms(item, entry)
        (unit_price_cents * weight).round if weight
      when "UNIT"
        (unit_price_cents * unit_count(item)).round
      end
      return if amount_cents.nil?

      price_attributes(
        amount_cents: [amount_cents, 1].max,
        unit_price_cents: unit_price_cents,
        price_unit: quote[:price_per] == "KILOGRAM" ? "kg" : "pièce",
        source: "open_prices",
        observed_on: quote[:observed_on],
        confidence: "observed"
      )
    end

    def estimate_from_reference(item, entry)
      specific_entry = entry.present?
      entry ||= CATEGORY_DEFAULTS.fetch(item.category.to_s, CATEGORY_DEFAULTS.fetch("autre"))

      case entry.fetch(:mode)
      when :weight
        weight = weight_in_kilograms(item, entry) || entry.fetch(:default_weight_g, 500).to_f / 1_000
        price_attributes(
          amount_cents: [(entry.fetch(:unit_price_cents) * weight).round, 1].max,
          unit_price_cents: entry.fetch(:unit_price_cents),
          price_unit: "kg",
          source: specific_entry ? "reference_catalog" : "category_average",
          observed_on: REFERENCE_DATE,
          confidence: specific_entry ? "reference" : "low"
        )
      when :unit
        price_attributes(
          amount_cents: (entry.fetch(:unit_price_cents) * unit_count(item)).round,
          unit_price_cents: entry.fetch(:unit_price_cents),
          price_unit: "pièce",
          source: "reference_catalog",
          observed_on: REFERENCE_DATE,
          confidence: "reference"
        )
      when :package
        packages = package_count(item, entry)
        price_attributes(
          amount_cents: entry.fetch(:package_price_cents) * packages,
          unit_price_cents: entry.fetch(:package_price_cents),
          price_unit: "paquet",
          source: specific_entry ? "reference_catalog" : "category_average",
          observed_on: REFERENCE_DATE,
          confidence: specific_entry ? "reference" : "low"
        )
      end
    end

    def weight_in_kilograms(item, entry)
      quantity = item.quantity_value&.to_f

      case item.quantity_unit
      when "g"
        quantity / 1_000 if quantity
      when "piece"
        quantity.ceil * entry[:piece_weight_g].to_f / 1_000 if quantity && entry[:piece_weight_g]
      end
    end

    def unit_count(item)
      quantity = item.quantity_value&.to_f
      return 1 unless item.quantity_unit == "piece" && quantity

      [quantity.ceil, 1].max
    end

    def package_count(item, entry)
      quantity = item.quantity_value&.to_f
      required = if quantity && item.quantity_unit == entry[:package_unit]
        quantity
      end
      return 1 unless required && entry[:package_quantity].to_f.positive?

      [(required / entry[:package_quantity].to_f).ceil, 1].max
    end

    def price_attributes(amount_cents:, unit_price_cents:, price_unit:, source:, observed_on:, confidence:)
      {
        estimated_price_cents: amount_cents,
        estimated_unit_price_cents: unit_price_cents,
        price_unit: price_unit,
        price_source: source,
        price_observed_on: observed_on,
        price_confidence: confidence
      }
    end
  end
end
