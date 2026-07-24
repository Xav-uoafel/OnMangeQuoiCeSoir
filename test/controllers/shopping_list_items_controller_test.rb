require "test_helper"

class ShoppingListItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    start_date = Date.current - ((Date.current.wday + 6) % 7)
    @plan = @user.plans.create!(
      start_date: start_date,
      end_date: start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30, dietary_restrictions: [], excluded_ingredients: [] },
      status: "generated"
    )
    @shopping_list = @plan.create_shopping_list!(user: @user)
    @item = @shopping_list.shopping_list_items.create!(name: "riz", quantity_text: "1 kg", category: "epicerie")
  end

  test "met a jour l'etat coche d'un article" do
    sign_in @user

    patch plan_shopping_list_shopping_list_item_path(@plan, @item),
          params: { shopping_list_item: { checked: "1" } }

    assert_redirected_to plan_shopping_list_path(@plan)
    assert @item.reload.checked?
  end
end
