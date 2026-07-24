require "application_system_test_case"

class PantryItemsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "adds an ingredient and exposes usable mobile navigation" do
    use_mobile_viewport
    visit pantry_items_path

    assert_no_horizontal_overflow
    assert_selector "nav[aria-label='Navigation mobile']", visible: true
    assert_minimum_touch_target "nav[aria-label='Navigation mobile'] a"

    fill_in "Ingrédient", with: "Tomates"
    select "Légumes", from: "Catégorie"
    fill_in "Quantité", with: "500 g"
    click_button "Ajouter"

    assert_text "Ajout au stock : tomates."
    item = @user.pantry_items.order(:created_at).last
    assert_field "pantry_item_#{item.id}_quantity", with: "500 g"
    assert_equal "tomates", item.name
    assert_no_horizontal_overflow
  end
end
