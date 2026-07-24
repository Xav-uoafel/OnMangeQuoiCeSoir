require "test_helper"

class LLMIngredientDetectorTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :parameters

    def initialize(response)
      @response = response
    end

    def chat(parameters:)
      @parameters = parameters
      raise @response if @response.is_a?(Exception)

      @response
    end
  end

  setup do
    @previous_key = ENV.fetch("OPENAI_API_KEY", nil)
    @previous_model = ENV.fetch("OPENAI_VISION_MODEL", nil)
    ENV["OPENAI_API_KEY"] = "test-key"
    ENV["OPENAI_VISION_MODEL"] = "vision-test-model"
  end

  teardown do
    ENV["OPENAI_API_KEY"] = @previous_key
    ENV["OPENAI_VISION_MODEL"] = @previous_model
  end

  test "envoie les images encodees et normalise la reponse" do
    client = FakeClient.new(ingredient_response)
    source = "data:image/png;base64,aW1hZ2U="

    ingredients = LLM::IngredientDetector.new([source], client: client).detect

    assert_equal "vision-test-model", client.parameters[:model]
    image_content = client.parameters.dig(:messages, 1, :content, 1, :image_url)
    assert_equal source, image_content[:url]
    assert_equal "high", image_content[:detail]
    assert_equal(
      [
        { name: "Tomate cerise", category: "legume", quantity_text: "environ 5" },
        { name: "Mystère", category: "autre", quantity_text: nil }
      ],
      ingredients
    )
  end

  test "rejette une reponse non JSON" do
    response = { "choices" => [{ "message" => { "content" => "pas du json" } }] }
    detector = LLM::IngredientDetector.new(["data:image/png;base64,aW1hZ2U="], client: FakeClient.new(response))

    error = assert_raises(LLM::IngredientDetector::DetectionError) { detector.detect }

    assert_equal "invalid_response", error.code
  end

  test "traduit une panne reseau en erreur de service" do
    client = FakeClient.new(Faraday::ConnectionFailed.new("connexion impossible"))
    detector = LLM::IngredientDetector.new(["data:image/png;base64,aW1hZ2U="], client: client)

    error = assert_raises(LLM::IngredientDetector::DetectionError) { detector.detect }

    assert_equal "service_unavailable", error.code
  end

  test "signale une cle absente sans exposer de detail" do
    ENV.delete("OPENAI_API_KEY")

    error = assert_raises(LLM::IngredientDetector::DetectionError) do
      LLM::IngredientDetector.new(["data:image/png;base64,aW1hZ2U="])
    end

    assert_equal "service_unavailable", error.code
  end

  private

  def ingredient_response
    {
      "choices" => [{
        "message" => {
          "content" => {
            ingredients: [
              { name: "  Tomate   cerise  ", category: "legume", quantity_text: " environ  5 " },
              { name: "Mystère", category: "inconnue", quantity_text: nil },
              { name: "  ", category: "fruit", quantity_text: "1" }
            ]
          }.to_json
        }
      }]
    }
  end
end
