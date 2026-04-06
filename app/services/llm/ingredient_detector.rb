module LLM
  class IngredientDetector
    class DetectionError < StandardError; end

    def initialize(image_urls)
      @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
      @image_urls = Array(image_urls)
    end

    def detect
      response = @client.chat(
        parameters: {
          model: "gpt-4o",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: user_content }
          ],
          response_format: { type: "json_object" },
          max_tokens: 2000
        }
      )

      parse_response(response.dig("choices", 0, "message", "content"))
    rescue OpenAI::Error => e
      Rails.logger.error "Erreur OpenAI Vision : #{e.message}"
      raise DetectionError, "Erreur lors de la detection des ingredients : #{e.message}"
    end

    private

    def system_prompt
      <<~PROMPT
        Tu es un assistant culinaire expert en identification d'ingredients alimentaires.
        Analyse les photos fournies et identifie TOUS les ingredients alimentaires visibles.

        Pour chaque ingredient, fournis :
        - name: nom en francais (singulier)
        - category: une parmi legume, fruit, viande, poisson, produit_laitier, epicerie, condiment, boisson, autre
        - quantity_text: estimation approximative ("environ 500g", "3 pieces", "1 bouteille", "1 paquet")

        Regles :
        - Ignore les objets non-alimentaires (emballages vides, ustensiles, etc.)
        - Si un produit est dans un emballage, identifie le contenu (ex: "lait" pas "brique de lait")
        - Sois precis sur les quantites visibles
        - Regroupe les doublons (si 3 tomates sur 2 photos, compte 3 tomates au total)

        Reponds UNIQUEMENT en JSON : { "ingredients": [{ "name": "...", "category": "...", "quantity_text": "..." }] }
      PROMPT
    end

    def user_content
      content = [{ type: "text", text: "Identifie tous les ingredients alimentaires dans ces photos :" }]
      @image_urls.each do |url|
        content << { type: "image_url", image_url: { url: url, detail: "high" } }
      end
      content
    end

    def parse_response(content)
      json = JSON.parse(content)
      ingredients = json["ingredients"] || []

      ingredients.map do |item|
        {
          name: item["name"]&.strip,
          category: item["category"]&.strip,
          quantity_text: item["quantity_text"]&.strip
        }
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Erreur parsing detection ingredients : #{e.message}"
      raise DetectionError, "Format de reponse invalide"
    end
  end
end
