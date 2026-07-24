class PlanRecipe < ApplicationRecord
  REPLACEMENT_STATUSES = %w[ready generating failed].freeze

  belongs_to :plan
  belongs_to :recipe

  # Attributs suggérés
  # scheduled_for: date # Date prévue pour cette recette
  # meal_type: string  # Type de repas (déjeuner, dîner)
  
  validates :scheduled_for, presence: true
  validates :meal_type, presence: true
  validates :replacement_status, inclusion: { in: REPLACEMENT_STATUSES }

  def replacement_generating?
    replacement_status == "generating"
  end

  def replacement_failed?
    replacement_status == "failed"
  end
end
