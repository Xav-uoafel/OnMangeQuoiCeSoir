require "test_helper"

class ShoppingListsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def setup
    @user = users(:one)
    @start_date = Date.current - ((Date.current.wday + 6) % 7)
    @plan = @user.plans.create!(
      start_date: @start_date,
      end_date: @start_date + 6.days,
      constraints: { servings: 2, max_preparation_time: 30, dietary_restrictions: [], excluded_ingredients: [] },
      status: "generated"
    )
    @recipe = @user.recipes.create!(
      title: "Pates test",
      description: "Une recette simple pour tester la liste",
      ingredients: "200 g pâtes\n1 tomate",
      instructions: "Cuire puis servir.",
      servings: 2,
      preparation_time: 10,
      cooking_time: 12,
      difficulty: "Facile"
    )
    @plan.plan_recipes.create!(recipe: @recipe, scheduled_for: @start_date, meal_type: "Dîner")
  end

  test "affiche une liste de courses avec formulaires de coche persistants" do
    sign_in @user

    assert_enqueued_with(job: ShoppingListPriceEstimationJob) do
      get plan_shopping_list_path(@plan)
    end

    assert_response :success
    assert_select "h1", "Liste de courses"
    assert_select "h2", "Calcul du panier..."
    assert_select "form[action*=?]", "/shopping_list_items/"
    assert_select "input[name='shopping_list_item[checked]']"
  end

  test "permet de relancer l actualisation des prix" do
    sign_in @user
    shopping_list = ShoppingListGenerator.new(@plan).generate
    shopping_list.update!(price_estimation_status: "failed")

    assert_enqueued_with(job: ShoppingListPriceEstimationJob, args: [shopping_list.id, true]) do
      post refresh_prices_plan_shopping_list_path(@plan)
    end

    assert_redirected_to plan_shopping_list_path(@plan)
    assert shopping_list.reload.price_estimation_pending?
  end

  test "expose un echec quand l actualisation ne peut pas etre programmee" do
    sign_in @user
    shopping_list = ShoppingListGenerator.new(@plan).generate
    shopping_list.update!(price_estimation_status: "failed")
    failed_job = Struct.new(:successfully_enqueued?).new(false)
    original_enqueue = ShoppingListPriceEstimationJob.method(:perform_later)
    ShoppingListPriceEstimationJob.define_singleton_method(:perform_later) { |*_args| failed_job }

    post refresh_prices_plan_shopping_list_path(@plan)

    assert_redirected_to plan_shopping_list_path(@plan)
    assert shopping_list.reload.price_estimation_failed?
    assert_equal "L’actualisation n’a pas pu démarrer. Vous pouvez réessayer.", flash[:alert]
  ensure
    ShoppingListPriceEstimationJob.define_singleton_method(:perform_later, original_enqueue) if original_enqueue
  end
end
