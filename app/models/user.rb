class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :household, optional: true

  has_many :recipes
  has_many :reviews, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :cooked_recipes, dependent: :destroy
  has_many :pantry_items, dependent: :destroy
  has_many :pantry_scans, dependent: :destroy
  has_many :shopping_lists, dependent: :destroy

  validates :household_size, numericality: { greater_than: 0, less_than_or_equal_to: 20 }, allow_nil: true
  validates :preferred_max_prep_time, numericality: { greater_than: 0 }, allow_nil: true

  def liked_recipes(limit = 10)
    cooked_recipes.where(liked: true).order(created_at: :desc).limit(limit).includes(:recipe).map(&:recipe)
  end

  def disliked_recipes(limit = 10)
    cooked_recipes.where(liked: false).order(created_at: :desc).limit(limit).includes(:recipe).map(&:recipe)
  end

  def needs_onboarding?
    !onboarding_completed?
  end

  def household_admin?
    household_role == 'admin'
  end

  def in_household?
    household_id.present?
  end

  def household_pantry_items
    return pantry_items unless in_household?

    household.all_pantry_items
  end
end
