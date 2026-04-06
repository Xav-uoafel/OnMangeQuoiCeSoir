class RecipeGenerationJob < ApplicationJob
  queue_as :default

  def perform(plan_id)
    plan = Plan.find(plan_id)
    return unless plan.generating?

    generator = RecipeGeneratorService.new(plan)

    if generator.generate
      plan.update!(status: 'generated')
      broadcast_plan_update(plan)
    else
      plan.update!(status: 'failed')
      broadcast_plan_update(plan)
    end
  rescue StandardError => e
    Rails.logger.error "RecipeGenerationJob failed for plan #{plan_id}: #{e.message}"
    plan&.update!(status: 'failed')
    broadcast_plan_update(plan) if plan
  end

  private

  def broadcast_plan_update(plan)
    Turbo::StreamsChannel.broadcast_replace_to(
      "plan_#{plan.id}",
      target: "plan_status",
      partial: "plans/status",
      locals: { plan: plan }
    )
  end
end
