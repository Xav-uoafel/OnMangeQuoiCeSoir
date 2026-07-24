require "test_helper"

class PantryStockReconcilerTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @reconciler = PantryStockReconciler.new(@user)
  end

  test "met a jour un ingredient existant au lieu de creer un doublon" do
    @user.pantry_items.create!(
      name: "tomates",
      category: "legume",
      quantity_text: "2",
      detected_on: Date.yesterday,
      source: "manual"
    )

    assert_no_difference("@user.pantry_items.count") do
      item = @reconciler.upsert!(
        name: "Tomate",
        category: "legume",
        quantity_text: "4",
        detected_on: Date.current,
        source: "manual"
      )

      assert_equal "tomates", item.name
      assert_equal "4", item.quantity_text
      assert_equal Date.current, item.detected_on
    end
  end

  test "fusionne les doublons existants en gardant le plus recent" do
    old_item = @user.pantry_items.create!(
      name: "tomates",
      category: "legume",
      quantity_text: "2",
      detected_on: Date.yesterday,
      source: "manual",
      created_at: 2.days.ago
    )
    recent_item = @user.pantry_items.create!(
      name: "Tomate",
      category: "legume",
      quantity_text: "4",
      detected_on: Date.current,
      source: "photo_scan",
      created_at: Time.current
    )

    assert_difference("@user.pantry_items.count", -1) do
      assert_equal 1, @reconciler.merge_duplicates!
    end

    assert_not PantryItem.exists?(old_item.id)
    assert PantryItem.exists?(recent_item.id)
  end
end
