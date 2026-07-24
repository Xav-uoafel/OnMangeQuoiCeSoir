class PantryItem < ApplicationRecord
  belongs_to :user
  belongs_to :pantry_scan, optional: true

  CATEGORIES = %w[legume fruit viande poisson produit_laitier epicerie condiment boisson autre].freeze

  validates :name, presence: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true
  validates :source, inclusion: { in: %w[photo_scan manual] }

  scope :by_category, ->(cat) { where(category: cat) }
  scope :recent, -> { order(created_at: :desc) }
end
