require "test_helper"

class LLMRecipeGeneratorTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :calls

    def initialize(responses)
      @responses = responses
      @calls = 0
    end

    def chat(parameters:)
      @calls += 1
      response = @responses.shift
      raise response if response.is_a?(Exception)

      response
    end
  end

  def setup
    @previous_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-key"
  end

  def teardown
    ENV["OPENAI_API_KEY"] = @previous_key
  end

  test "parse une reponse avec recipe_ingredients structures" do
    recipe = LLM::RecipeGenerator.new({}).send(:parse_response, recipe_payload)

    assert_equal "Riz aux tomates", recipe.title
    assert_equal ["riz", "tomates"], recipe.recipe_ingredients.map { |item| item["name"] }
  end

  test "ne retente pas un quota epuise" do
    client = FakeClient.new([api_error("insufficient_quota")])
    sleeps = []
    generator = LLM::RecipeGenerator.new({}, client: client, sleeper: ->(duration) { sleeps << duration })

    error = assert_raises(LLM::RecipeGenerator::GenerationError) { generator.generate_recipe }

    assert_equal "insufficient_quota", error.code
    assert_not error.retryable
    assert_equal 1, client.calls
    assert_empty sleeps
  end

  test "retente une limite temporaire avec backoff" do
    response = { "choices" => [{ "message" => { "content" => recipe_payload } }] }
    client = FakeClient.new([api_error("rate_limit_exceeded"), api_error("rate_limit_exceeded"), response])
    sleeps = []
    generator = LLM::RecipeGenerator.new({}, client: client, sleeper: ->(duration) { sleeps << duration })

    recipe = generator.generate_recipe

    assert_equal "Riz aux tomates", recipe.title
    assert_equal 3, client.calls
    assert_equal [1, 2], sleeps
  end

  test "transmet la cible de prix au generateur" do
    generator = LLM::RecipeGenerator.new({ servings: 2, target_cost_per_meal_cents: 750 })

    assert_includes generator.send(:user_prompt), "7.50 €"
    assert_includes generator.send(:user_prompt), "produits simples et économiques"
  end

  private

  def recipe_payload
    {
      title: "Riz aux tomates",
      description: "Un plat simple et rapide",
      ingredients: "200 g riz\n2 tomates",
      instructions: "Cuire puis mélanger.",
      servings: 2,
      preparation_time: 10,
      cooking_time: 20,
      difficulty: "Facile",
      seasonal_ingredients_used: ["tomate"],
      recipe_ingredients: [
        { raw: "200 g riz", quantity: 200, unit: "g", name: "riz", category: "epicerie" },
        { raw: "2 tomates", quantity: 2, unit: "piece", name: "tomates", category: "legume" }
      ]
    }.to_json
  end

  def api_error(code)
    Faraday::TooManyRequestsError.new(
      "request failed",
      { status: 429, body: { "error" => { "code" => code, "type" => code } } }
    )
  end
end
