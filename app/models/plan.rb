class Plan < ApplicationRecord
  MAX_WEEKLY_BUDGET_CENTS = 1_000_000
  GENERATION_TIMEOUT = 10.minutes
  GENERATION_ERROR_MESSAGES = {
    "generation_failed" => "Nous n'avons pas pu composer cette semaine. Vos préférences sont conservées.",
    "queue_unavailable" => "Le service de génération est temporairement indisponible.",
    "technical_error" => "Un incident technique a interrompu la génération.",
    "timeout" => "La génération a pris trop de temps et peut être relancée."
  }.freeze

  belongs_to :user
  has_many :plan_recipes, dependent: :destroy
  has_many :recipes, through: :plan_recipes
  has_one :shopping_list, dependent: :destroy

  attribute :status, :string, default: 'draft'
  
  # Attributs suggérés
  # constraints: jsonb # Stocke les contraintes utilisées pour la génération
  # start_date: date  # Date de début du plan
  # end_date: date    # Date de fin du plan
  # status: string    # État du plan (draft, generated, etc.)
  
  validates :constraints, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :status, inclusion: { in: %w[draft generating generated failed] }
  validate :end_date_after_start_date
  validate :start_date_must_be_monday
  validate :end_date_must_be_sunday
  validate :weekly_budget_must_be_valid

  before_validation :ensure_constraints_format

  def generating?
    status == 'generating'
  end

  def generated?
    status == 'generated'
  end

  def failed?
    status == 'failed'
  end

  def start_generation!
    token = SecureRandom.uuid

    with_lock do
      update!(
        status: "generating",
        generation_token: token,
        generation_started_at: Time.current,
        generation_completed_at: nil,
        generation_error_code: nil,
        generation_attempts: generation_attempts + 1
      )
    end

    token
  end

  def current_generation?(token)
    generating? && token.present? && generation_token == token
  end

  def complete_generation!(token)
    transition_generation(
      token,
      status: "generated",
      generation_completed_at: Time.current,
      generation_error_code: nil
    )
  end

  def fail_generation!(token, code: "technical_error")
    transition_generation(
      token,
      status: "failed",
      generation_completed_at: Time.current,
      generation_error_code: code
    )
  end

  def generation_stale?(now: Time.current)
    return false unless generating?

    generation_started_at.blank? || generation_started_at < now - GENERATION_TIMEOUT
  end

  def generation_error_message
    GENERATION_ERROR_MESSAGES.fetch(generation_error_code, GENERATION_ERROR_MESSAGES.fetch("technical_error"))
  end

  def meal_slots
    return [] if start_date.blank? || end_date.blank?

    (start_date..end_date).flat_map do |date|
      weekend = date.saturday? || date.sunday?
      slots = []
      slots << [date, "Déjeuner"] if (weekend && weekend_lunches) || (!weekend && weekday_lunches)
      slots << [date, "Dîner"] if (weekend && weekend_dinners) || (!weekend && weekday_dinners)
      slots
    end
  end

  def planned_meals_count
    meal_slots.size
  end

  def weekly_budget_cents
    constraints.to_h.with_indifferent_access[:weekly_budget_cents].presence&.to_i
  end

  def weekly_budget
    return if weekly_budget_cents.blank?

    weekly_budget_cents / 100.0
  end

  def weekly_budget?
    weekly_budget_cents.to_i.positive?
  end

  def target_cost_per_meal_cents
    return unless weekly_budget? && planned_meals_count.positive?

    (weekly_budget_cents.to_f / planned_meals_count).round
  end

  def estimated_total_cents
    return unless shopping_list&.prices_ready?

    shopping_list.estimated_total_cents
  end

  def estimated_cost_per_meal_cents
    return unless estimated_total_cents && planned_meals_count.positive?

    (estimated_total_cents.to_f / planned_meals_count).round
  end

  def budget_difference_cents
    return unless weekly_budget? && estimated_total_cents

    weekly_budget_cents - estimated_total_cents
  end

  def over_budget?
    budget_difference_cents&.negative? || false
  end

  def budget_usage_percentage
    return unless weekly_budget? && estimated_total_cents

    (estimated_total_cents.to_f / weekly_budget_cents * 100).round
  end

  private

  def transition_generation(token, attributes)
    transitioned = false

    with_lock do
      if current_generation?(token)
        update!(attributes.merge(generation_token: nil))
        transitioned = true
      end
    end

    transitioned
  end

  def ensure_constraints_format
    return if constraints.blank?

    normalized = constraints.to_h.with_indifferent_access

    self.constraints = {
      servings: normalized[:servings].presence&.to_i || user&.household_size || 4,
      max_preparation_time: normalized[:max_preparation_time].presence&.to_i || user&.preferred_max_prep_time || 45,
      dietary_restrictions: Array(normalized[:dietary_restrictions]).reject(&:blank?),
      excluded_ingredients: Array(normalized[:excluded_ingredients]).reject(&:blank?),
      weekly_budget_cents: normalized[:weekly_budget_cents].presence&.to_i
    }
  end

  def weekly_budget_must_be_valid
    return if weekly_budget_cents.blank?

    unless weekly_budget_cents.between?(1, MAX_WEEKLY_BUDGET_CENTS)
      errors.add(:constraints, "doit contenir un budget compris entre 0,01 € et 10 000 €")
    end
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
