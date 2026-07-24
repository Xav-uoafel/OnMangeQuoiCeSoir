require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "demo seeds are idempotent and preserve existing records" do
    existing_user = users(:one)

    with_demo_seeds_enabled do
      load Rails.root.join("db/seeds.rb")
      first_counts = [User.count, Recipe.count, Review.count]

      load Rails.root.join("db/seeds.rb")

      assert_equal first_counts, [User.count, Recipe.count, Review.count]
    end

    assert User.exists?(existing_user.id)
    assert User.exists?(email: "chef@example.com")
    assert User.exists?(email: "gourmet@example.com")
  end

  private

  def with_demo_seeds_enabled
    previous_value = ENV.fetch("SEED_DEMO_DATA", nil)
    ENV["SEED_DEMO_DATA"] = "1"
    yield
  ensure
    ENV["SEED_DEMO_DATA"] = previous_value
  end
end
