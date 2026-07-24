require "test_helper"

class RecipeGenerationJobTest < ActiveJob::TestCase
  FakeGenerator = Struct.new(:result, :fallback_used?) do
    def generate
      result
    end
  end

  setup do
    start_date = Date.current.beginning_of_week(:monday)
    @plan = users(:one).plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      status: "generating",
      constraints: {
        servings: 2,
        max_preparation_time: 30,
        dietary_restrictions: [],
        excluded_ingredients: []
      }
    )
    @plan.plan_recipes.create!(
      recipe: recipes(:one),
      scheduled_for: start_date,
      meal_type: "Dîner"
    )
    @generation_token = @plan.start_generation!
  end

  test "renders a generated plan from the background job context" do
    html = ApplicationController.render(
      partial: "plans/status",
      locals: { plan: @plan.tap { |plan| plan.update!(status: "generated") } }
    )

    assert_includes html, recipes(:one).title
  end

  test "keeps the generated status when the Turbo broadcast fails" do
    generator = FakeGenerator.new(true, false)
    original_generator = RecipeGeneratorService.method(:new)
    original_broadcast = Turbo::StreamsChannel.method(:broadcast_update_to)

    RecipeGeneratorService.define_singleton_method(:new) { |_plan| generator }
    Turbo::StreamsChannel.define_singleton_method(:broadcast_update_to) do |*_args, **_kwargs|
      raise "Action Cable unavailable"
    end

    RecipeGenerationJob.perform_now(@plan.id, @generation_token)
    assert @plan.reload.generated?
  ensure
    RecipeGeneratorService.define_singleton_method(:new, original_generator) if original_generator
    Turbo::StreamsChannel.define_singleton_method(:broadcast_update_to, original_broadcast) if original_broadcast
  end

  test "ignore une ancienne tentative apres une relance" do
    old_token = @generation_token
    new_token = @plan.start_generation!

    RecipeGenerationJob.perform_now(@plan.id, old_token)

    assert @plan.reload.current_generation?(new_token)
  end
end
