class ShoppingList < ApplicationRecord
  PRICE_ESTIMATION_STATUSES = %w[pending estimating estimated partial failed].freeze

  belongs_to :plan
  belongs_to :user
  has_many :shopping_list_items, dependent: :destroy

  validates :status, inclusion: { in: %w[active completed] }
  validates :price_estimation_status, inclusion: { in: PRICE_ESTIMATION_STATUSES }

  def progress_percentage
    return 0 if total_items_count.zero?

    (checked_items_count.to_f / total_items_count * 100).round
  end

  def items_by_category
    shopping_list_items.load.sort_by { |item| [item.category.to_s, item.name.to_s] }.group_by(&:category)
  end

  def total_items_count
    items_loaded? ? loaded_items.size : shopping_list_items.count
  end

  def checked_items_count
    items_loaded? ? loaded_items.count(&:checked?) : shopping_list_items.where(checked: true).count
  end

  def remaining_items_count
    total_items_count - checked_items_count
  end

  def price_estimation_pending?
    price_estimation_status == "pending"
  end

  def price_estimation_in_progress?
    price_estimation_status.in?(%w[pending estimating])
  end

  def price_estimation_failed?
    price_estimation_status == "failed"
  end

  def prices_ready?
    price_estimation_status.in?(%w[estimated partial])
  end

  def estimated_total_cents
    return loaded_items.sum { |item| item.estimated_price_cents.to_i } if items_loaded?

    shopping_list_items.sum(:estimated_price_cents)
  end

  def remaining_total_cents
    return loaded_items.reject(&:checked?).sum { |item| item.estimated_price_cents.to_i } if items_loaded?

    shopping_list_items.where(checked: false).sum(:estimated_price_cents)
  end

  def priced_items_count
    return loaded_items.count { |item| item.estimated_price_cents.present? } if items_loaded?

    shopping_list_items.where.not(estimated_price_cents: nil).count
  end

  def observed_price_items_count
    return loaded_items.count(&:observed_price?) if items_loaded?

    shopping_list_items.where(price_source: "open_prices").count
  end

  def price_coverage_percentage
    return 0 if total_items_count.zero?

    (priced_items_count.to_f / total_items_count * 100).round
  end

  def observed_price_percentage
    return 0 if total_items_count.zero?

    (observed_price_items_count.to_f / total_items_count * 100).round
  end

  def latest_price_observed_on
    return loaded_items.filter_map(&:price_observed_on).max if items_loaded?

    shopping_list_items.maximum(:price_observed_on)
  end

  private

  def items_loaded?
    shopping_list_items.loaded?
  end

  def loaded_items
    shopping_list_items.target
  end
end
