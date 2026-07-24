require "openai"

module LLM
  class IngredientDetector
    DEFAULT_MODEL = "gpt-4.1-mini".freeze
    MAX_INGREDIENTS = 100
    MAX_NAME_LENGTH = 100
    MAX_QUANTITY_LENGTH = 80

    class DetectionError < StandardError
      attr_reader :code, :retryable

      def initialize(message, code: "technical_error", retryable: false)
        super(message)
        @code = code
        @retryable = retryable
      end
    end

    def initialize(image_sources, client: nil)
      @client = client || build_client
      @image_sources = Array(image_sources).compact_blank
      @model = ENV.fetch("OPENAI_VISION_MODEL", DEFAULT_MODEL)
      @detail = ENV.fetch("OPENAI_VISION_DETAIL", "high")
    end

    def detect
      validate_image_sources!
      response = @client.chat(parameters: request_parameters)
      parse_response(response.dig("choices", 0, "message", "content"))
    rescue DetectionError
      raise
    rescue Faraday::TooManyRequestsError => e
      raise_service_error(e, retryable: true)
    rescue Faraday::Error, OpenAI::Error => e
      raise_service_error(e)
    end

    private

    def build_client
      api_key = ENV.fetch("OPENAI_API_KEY", nil).presence
      raise DetectionError.new("Clé OpenAI absente", code: "service_unavailable") unless api_key

      OpenAI::Client.new(access_token: api_key)
    end

    def validate_image_sources!
      return if @image_sources.any?

      raise DetectionError.new("Aucune image à analyser", code: "invalid_response")
    end

    def request_parameters
      {
        model: @model,
        messages: [
          { role: "system", content: IngredientDetectionPrompt.system_prompt },
          { role: "user", content: user_content }
        ],
        response_format: { type: "json_object" },
        max_tokens: 2000
      }
    end

    def user_content
      content = [{ type: "text", text: "Identifie tous les ingredients alimentaires dans ces photos :" }]
      @image_sources.each do |source|
        content << { type: "image_url", image_url: { url: source, detail: @detail } }
      end
      content
    end

    def parse_response(content)
      ingredient_payload(content).first(MAX_INGREDIENTS).filter_map { |item| normalize_item(item) }
    end

    def ingredient_payload(content)
      json = JSON.parse(content.to_s)
      ingredients = json["ingredients"] if json.is_a?(Hash)
      return ingredients if ingredients.is_a?(Array)

      raise DetectionError.new("Format de réponse invalide", code: "invalid_response")
    rescue JSON::ParserError, TypeError => e
      Rails.logger.warn "OpenAI ingredient detection returned invalid JSON: #{e.class}"
      raise DetectionError.new("Format de réponse invalide", code: "invalid_response")
    end

    def normalize_item(item)
      return unless item.is_a?(Hash)

      name = normalize_text(item["name"], MAX_NAME_LENGTH)
      return if name.blank?

      category = normalize_text(item["category"], 40)
      {
        name: name,
        category: category.in?(PantryItem::CATEGORIES) ? category : "autre",
        quantity_text: normalize_text(item["quantity_text"], MAX_QUANTITY_LENGTH)
      }
    end

    def normalize_text(value, limit)
      value.to_s.squish.first(limit).presence
    end

    def report_api_error(error)
      status = error.respond_to?(:response) && error.response.is_a?(Hash) ? error.response[:status] : nil
      Rails.logger.error "OpenAI ingredient detection failed: class=#{error.class} status=#{status || 'unknown'}"
    end

    def raise_service_error(error, retryable: false)
      report_api_error(error)
      raise DetectionError.new(
        "Le service d’analyse est indisponible",
        code: "service_unavailable",
        retryable: retryable
      )
    end
  end
end
