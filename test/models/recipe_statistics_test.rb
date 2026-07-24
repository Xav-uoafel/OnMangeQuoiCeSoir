require "test_helper"

class RecipeStatisticsTest < ActiveSupport::TestCase
  test "reutilise les avis precharges sans nouvelle requete" do
    recipe = Recipe.includes(:reviews).find(recipes(:one).id)

    assert_no_queries do
      assert_equal 4.0, recipe.average_rating
      assert_equal 1, recipe.total_reviews
    end
  end
end
