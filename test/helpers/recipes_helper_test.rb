require 'test_helper'

class RecipesHelperTest < ActionView::TestCase
  test "rating_stars affiche le bon nombre d'étoiles" do
    # Test avec une note de 4 sur 5
    result = rating_stars(4.0)
    assert_match(/text-yellow-400.*svg.*svg.*svg.*svg/, result) # 4 étoiles pleines
    assert_match(/text-gray-300.*svg/, result) # 1 étoile vide

    # Test avec une note de 0 sur 5
    result = rating_stars(0.0)
    assert_match(/text-gray-300.*svg.*svg.*svg.*svg.*svg/, result) # 5 étoiles vides

    # Test avec une note de 5 sur 5
    result = rating_stars(5.0)
    assert_match(/text-yellow-400.*svg.*svg.*svg.*svg.*svg/, result) # 5 étoiles pleines
  end
end 