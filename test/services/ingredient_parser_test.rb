require "test_helper"

class IngredientParserTest < ActiveSupport::TestCase
  test "parse une ligne avec quantite et unite" do
    result = IngredientParser.parse_line("200 g tomates")

    assert_equal 200.0, result[:quantity]
    assert_equal "g", result[:unit]
    assert_equal "tomates", result[:name]
    assert_equal "legume", result[:category]
  end

  test "parse une ligne sans quantite" do
    result = IngredientParser.parse_line("sel")

    assert_nil result[:quantity]
    assert_nil result[:unit]
    assert_equal "sel", result[:name]
  end

  test "normalise un nom canonique pour les comparaisons" do
    assert_equal "tomate", IngredientParser.canonical_name("Tomates")
    assert_equal "pate brisee", IngredientParser.canonical_name("de la pâte brisée")
  end

  test "convertit les unites compatibles vers une unite canonique" do
    assert_equal [1_500.0, "g"], IngredientParser.canonical_quantity(1.5, "kg")
    assert_equal [500.0, "ml"], IngredientParser.canonical_quantity(50, "cl")
    assert_equal [nil, "g"], IngredientParser.canonical_quantity(nil, "kg")
  end
end
