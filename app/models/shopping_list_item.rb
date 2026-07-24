class ShoppingListItem < ApplicationRecord
  PRICE_SOURCES = %w[open_prices reference_catalog category_average].freeze
  PRICE_CONFIDENCES = %w[observed reference low].freeze

  belongs_to :shopping_list

  validates :name, presence: true
  validates :estimated_price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :estimated_unit_price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_source, inclusion: { in: PRICE_SOURCES }, allow_nil: true
  validates :price_confidence, inclusion: { in: PRICE_CONFIDENCES }, allow_nil: true

  def observed_price?
    price_source == "open_prices"
  end
end
