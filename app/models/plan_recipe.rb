class PlanRecipe < ApplicationRecord
  belongs_to :plan
  belongs_to :recipe

  # Attributs suggérés
  # scheduled_for: date # Date prévue pour cette recette
  # meal_type: string  # Type de repas (déjeuner, dîner)
  
  validates :scheduled_for, presence: true
  validates :meal_type, presence: true
end 