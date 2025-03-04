class Plan < ApplicationRecord
  belongs_to :user
  has_many :plan_recipes, dependent: :destroy
  has_many :recipes, through: :plan_recipes

  attribute :status, :string, default: 'draft'
  
  # Attributs suggérés
  # constraints: jsonb # Stocke les contraintes utilisées pour la génération
  # start_date: date  # Date de début du plan
  # end_date: date    # Date de fin du plan
  # status: string    # État du plan (draft, generated, etc.)
  
  validates :constraints, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, inclusion: { in: %w[draft generated] }
  validate :end_date_after_start_date
  validate :start_date_must_be_monday
  validate :end_date_must_be_sunday

  before_validation :ensure_constraints_format

  private

  def ensure_constraints_format
    return if constraints.blank?
    
    self.constraints = {
      servings: constraints[:servings].presence&.to_i,
      max_preparation_time: constraints[:max_preparation_time].presence&.to_i,
      dietary_restrictions: Array(constraints[:dietary_restrictions]).reject(&:blank?),
      excluded_ingredients: Array(constraints[:excluded_ingredients]).reject(&:blank?)
    }
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    
    if end_date < start_date
      errors.add(:end_date, "doit être après la date de début")
    end
  end

  def start_date_must_be_monday
    return if start_date.blank?
    
    unless start_date.monday?
      errors.add(:start_date, "doit être un lundi")
    end
  end

  def end_date_must_be_sunday
    return if end_date.blank?
    
    unless end_date.sunday?
      errors.add(:end_date, "doit être un dimanche")
    end
  end
end 