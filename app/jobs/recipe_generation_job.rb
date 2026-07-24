class RecipeGenerationJob < ApplicationJob
  queue_as :default

  def perform(plan_id, generation_token = nil)
    plan = Plan.find(plan_id)
    return unless plan.current_generation?(generation_token)

    generator = RecipeGeneratorService.new(plan)
    return unless persist_generation_result(plan, generator, generation_token)

    log_fallback(plan, generator)
    broadcast_plan_update(plan)
  rescue StandardError => e
    handle_failure(plan, plan_id, generation_token, e)
  end

  private

  def persist_generation_result(plan, generator, generation_token)
    if generator.generate
      plan.complete_generation!(generation_token)
    else
      plan.fail_generation!(generation_token, code: "generation_failed")
    end
  end

  def log_fallback(plan, generator)
    return unless plan.generated? && generator.fallback_used?

    Rails.logger.info "Plan #{plan.id} généré avec le catalogue local"
  end

  def handle_failure(plan, plan_id, generation_token, error)
    Rails.logger.error "RecipeGenerationJob failed for plan #{plan_id}: #{error.class} - #{error.message}"
    Rails.error.report(error, handled: true)
    transitioned = plan&.fail_generation!(generation_token, code: "technical_error")
    broadcast_plan_update(plan) if transitioned
  end

  def broadcast_plan_update(plan)
    Turbo::StreamsChannel.broadcast_update_to(
      "plan_#{plan.id}",
      target: "plan_status",
      partial: "plans/status",
      locals: { plan: plan }
    )
  rescue StandardError => e
    Rails.logger.error "RecipeGenerationJob broadcast failed for plan #{plan.id}: #{e.class} - #{e.message}"
  end
end
