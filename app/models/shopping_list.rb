class ShoppingList < ApplicationRecord
  belongs_to :plan
  belongs_to :user
  has_many :shopping_list_items, dependent: :destroy

  validates :status, inclusion: { in: %w[active completed] }

  def progress_percentage
    return 0 if shopping_list_items.empty?

    (shopping_list_items.where(checked: true).count.to_f / shopping_list_items.count * 100).round
  end

  def items_by_category
    shopping_list_items.order(:category, :name).group_by(&:category)
  end
end
