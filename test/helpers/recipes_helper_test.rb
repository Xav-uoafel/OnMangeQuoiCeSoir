require 'test_helper'

class RecipesHelperTest < ActionView::TestCase
  test "rating_stars affiche le bon nombre d'étoiles" do
    # Test avec une note de 4 sur 5
    result = rating_stars(4.0)
    assert_equal 4, result.scan("text-yellow-300").size
    assert_equal 1, result.scan("text-gray-300").size

    # Test avec une note de 0 sur 5
    result = rating_stars(0.0)
    assert_equal 5, result.scan("text-gray-300").size

    # Test avec une note de 5 sur 5
    result = rating_stars(5.0)
    assert_equal 5, result.scan("text-yellow-300").size
  end
end
