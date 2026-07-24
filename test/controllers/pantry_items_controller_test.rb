require "test_helper"

class PantryItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
  end

  test "affiche le stock avec les formulaires d'edition" do
    sign_in @user
    @user.pantry_items.create!(
      name: "riz",
      category: "epicerie",
      quantity_text: "1 kg",
      detected_on: Date.current,
      source: "manual"
    )

    get pantry_items_path

    assert_response :success
    assert_select "form[action=?]", pantry_item_path(@user.pantry_items.last)
    assert_select "input[name='pantry_item[name]']"
  end

  test "ajoute un ingredient sans creer de doublon canonique" do
    sign_in @user
    @user.pantry_items.create!(
      name: "tomates",
      category: "legume",
      quantity_text: "2",
      detected_on: Date.current,
      source: "manual"
    )

    assert_no_difference("@user.pantry_items.count") do
      post pantry_items_path, params: {
        pantry_item: {
          name: "Tomate",
          category: "legume",
          quantity_text: "4"
        }
      }
    end

    assert_redirected_to pantry_items_path
    assert_equal "4", @user.pantry_items.find_by!(name: "tomates").quantity_text
  end

  test "fusionne les doublons existants" do
    sign_in @user
    @user.pantry_items.create!(name: "riz", category: "epicerie", quantity_text: "1 kg", detected_on: Date.current, source: "manual")
    @user.pantry_items.create!(name: "Riz", category: "epicerie", quantity_text: "500 g", detected_on: Date.current, source: "manual")

    assert_difference("@user.pantry_items.count", -1) do
      post merge_duplicates_pantry_items_path
    end

    assert_redirected_to pantry_items_path
  end
end
