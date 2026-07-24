require "test_helper"

class PlanGenerationTest < ActiveSupport::TestCase
  setup do
    start_date = Date.current.beginning_of_week(:monday)
    @plan = users(:one).plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30 }
    )
  end

  test "suit les tentatives et neutralise les anciens jetons" do
    first_token = @plan.start_generation!
    second_token = @plan.start_generation!

    assert_equal 2, @plan.generation_attempts
    assert @plan.current_generation?(second_token)
    assert_not @plan.current_generation?(first_token)
    assert_not @plan.complete_generation!(first_token)
    assert @plan.generating?

    assert @plan.complete_generation!(second_token)
    assert @plan.generated?
    assert_nil @plan.generation_token
    assert_not_nil @plan.generation_completed_at
  end

  test "detecte une generation bloquee" do
    @plan.start_generation!
    @plan.update!(generation_started_at: 11.minutes.ago)

    assert @plan.generation_stale?
  end

  test "expose un message utilisateur sans detail technique" do
    token = @plan.start_generation!
    @plan.fail_generation!(token, code: "queue_unavailable")

    assert @plan.failed?
    assert_includes @plan.generation_error_message, "temporairement indisponible"
  end
end
