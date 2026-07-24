require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "mobile_nav_item_class marque la section active" do
    define_singleton_method(:controller_name) { "plans" }

    assert_includes mobile_nav_item_class(:plan), "mobile-bottom-nav-item-active"
    assert_not_includes mobile_nav_item_class(:stock), "mobile-bottom-nav-item-active"
    assert_equal "page", mobile_nav_aria_current(:plan)
    assert_nil mobile_nav_aria_current(:stock)
  end

  test "dietary_restriction_label traduit les restrictions" do
    assert_equal "Végétarien", dietary_restriction_label("vegetarien")
    assert_equal "Sans gluten", dietary_restriction_label("sans_gluten")
  end

  test "format_estimated_price affiche un montant en euros" do
    assert_equal "12,50 €", format_estimated_price(1_250)
    assert_equal "Non estimé", format_estimated_price(nil)
  end
end
