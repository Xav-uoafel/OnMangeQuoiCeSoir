class PantryStockReconciler
  def initialize(user)
    @user = user
  end

  def upsert!(attributes)
    attrs = normalize_attributes(attributes)
    existing = find_existing(attrs[:name])

    if existing
      existing.update!(merged_attributes(existing, attrs))
      existing
    else
      @user.pantry_items.create!(attrs)
    end
  end

  def merge_duplicates!
    merged_count = 0

    ActiveRecord::Base.transaction do
      duplicate_groups.each_value do |items|
        keeper = items.max_by(&:created_at)
        duplicates = items - [keeper]
        next if duplicates.empty?

        keeper.update!(attributes_from_duplicates(keeper, duplicates))
        PantryItem.where(id: duplicates.map(&:id)).destroy_all
        merged_count += duplicates.size
      end
    end

    merged_count
  end

  private

  def normalize_attributes(attributes)
    attrs = attributes.to_h.symbolize_keys.slice(:name, :category, :quantity_text, :detected_on, :source, :pantry_scan)
    attrs[:name] = IngredientParser.normalize_name(attrs[:name])
    attrs[:category] = attrs[:category].presence || IngredientParser.guess_category(attrs[:name])
    attrs[:detected_on] ||= Date.current
    attrs[:source] ||= "manual"
    attrs
  end

  def find_existing(name)
    canonical = IngredientParser.canonical_name(name)
    @user.pantry_items.find { |item| IngredientParser.canonical_name(item.name) == canonical }
  end

  def duplicate_groups
    @user.pantry_items.to_a.group_by { |item| IngredientParser.canonical_name(item.name) }.select do |canonical, items|
      canonical.present? && items.size > 1
    end
  end

  def merged_attributes(existing, attrs)
    {
      category: attrs[:category].presence || existing.category,
      quantity_text: attrs[:quantity_text].presence || existing.quantity_text,
      detected_on: attrs[:detected_on].presence || existing.detected_on,
      source: attrs[:source].presence || existing.source,
      pantry_scan: attrs[:pantry_scan].presence || existing.pantry_scan
    }
  end

  def attributes_from_duplicates(keeper, duplicates)
    {
      category: keeper.category.presence || first_present(duplicates, :category),
      quantity_text: keeper.quantity_text.presence || first_present(duplicates, :quantity_text),
      detected_on: ([keeper.detected_on] + duplicates.map(&:detected_on)).compact.max,
      source: keeper.source.presence || first_present(duplicates, :source),
      pantry_scan: keeper.pantry_scan || duplicates.find(&:pantry_scan)&.pantry_scan
    }
  end

  def first_present(items, attribute)
    items.map { |item| item.public_send(attribute) }.find(&:present?)
  end
end
