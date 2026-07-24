# frozen_string_literal: true

require 'openai'

module LLM
  class RecipeGenerator
    DEFAULT_MODEL = "gpt-4.1-mini"
    MAX_RATE_LIMIT_RETRIES = 2

    class GenerationError < StandardError
      attr_reader :code, :retryable

      def initialize(message, code: nil, retryable: false)
        super(message)
        @code = code
        @retryable = retryable
      end
    end

    def initialize(constraints, user_context: {}, client: nil, sleeper: nil)
      @constraints = constraints
      @user_context = user_context
      @client = client || OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
      @sleeper = sleeper || ->(duration) { sleep(duration) }
      @model = ENV.fetch("OPENAI_MODEL", DEFAULT_MODEL)
    end

    def generate_recipe
      attempts = 0

      begin
        response = @client.chat(
          parameters: {
            model: @model,
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: user_prompt }
            ],
            response_format: { type: "json_object" },
            temperature: 0.7
          }
        )

        parse_response(response.dig("choices", 0, "message", "content"))
      rescue Faraday::TooManyRequestsError => e
        code = api_error_details(e)[:code]
        retryable = code != "insufficient_quota"

        if retryable && attempts < MAX_RATE_LIMIT_RETRIES
          @sleeper.call(2**attempts)
          attempts += 1
          retry
        end

        raise_api_error(e, code: code, retryable: retryable)
      rescue Faraday::Error, OpenAI::Error => e
        raise_api_error(e, code: api_error_details(e)[:code], retryable: false)
      end
    end

    private

    def system_prompt
      seasonal = SeasonalIngredientsService.current
      <<~PROMPT
        Tu es un chef cuisinier expert qui génère des recettes détaillées en français.
        Pour cette recette, utilise de préférence les ingrédients de saison suivants :
        
        Légumes de saison : #{seasonal[:vegetables].join(', ')}
        Fruits de saison : #{seasonal[:fruits].join(', ')}
        
        IMPORTANT : 
        1. Ta réponse DOIT être UNIQUEMENT un objet JSON valide, sans aucun texte avant ou après.
        2. Ne réponds pas avec du texte, des explications ou des excuses.
        3. Génère des recettes VARIÉES (plats principaux, entrées, desserts) et en minimisant le nombre de soupes ou potages maximum deux fois par semaine et les plats similaires par exemple un poulet roti aux légumes de saisin et un poulet roti aux herbes de provence.
        4. Si aucune restriction alimentaire n'est spécifiée, tu peux inclure de la viande, du poisson et des fruits de mer.
        5. Adapte PRÉCISÉMENT les quantités d'ingrédients au nombre de personnes spécifié. Par exemple, pour 4 personnes : "400g de viande", pour 2 personnes : "200g de viande".
        6. Si aucun nombre de personnes n'est spécifié, prévois la recette pour 4 personnes par défaut.
        7. Pour les ingrédients, fournis aussi une version structurée dans recipe_ingredients.
        8. recipe_ingredients doit être un tableau d'objets avec exactement : raw, quantity, unit, name, category.
        9. category doit être une des valeurs suivantes : legume, fruit, viande, poisson, produit_laitier, epicerie, condiment, boisson, autre.
        10. quantity doit être un nombre quand c'est possible, sinon null. unit doit être une chaîne courte ("g", "kg", "ml", "l", "piece", etc.) ou null.
        
        #{user_context_prompt}
        Génère une recette au format JSON avec exactement les champs suivants :
        {
          "title": "Titre de la recette",
          "description": "Description courte",
          "ingredients": "Liste des ingrédients avec quantités PRÉCISES adaptées au nombre de personnes, un ingrédient par ligne",
          "instructions": "Instructions étape par étape sous forme de texte, pas de tableau",
          "servings": nombre de portions,
          "preparation_time": temps en minutes,
          "cooking_time": temps en minutes,
          "difficulty": "Facile|Intermédiaire|Difficile",
          "seasonal_ingredients_used": ["liste", "des", "ingrédients", "de", "saison", "utilisés"],
          "recipe_ingredients": [
            {
              "raw": "200g de riz",
              "quantity": 200,
              "unit": "g",
              "name": "riz",
              "category": "epicerie"
            }
          ]
        }
      PROMPT
    end

    def user_prompt
      constraints_text = []
      if @constraints[:servings].present?
        constraints_text << "Pour EXACTEMENT #{@constraints[:servings]} personnes (adapte précisément les quantités d'ingrédients)"
      else
        constraints_text << "Pour 4 personnes"
      end
      
      constraints_text << "Temps de préparation maximum : #{@constraints[:max_preparation_time]} minutes" if @constraints[:max_preparation_time].present?

      if @constraints[:target_cost_per_meal_cents].to_i.positive?
        target = format("%.2f", @constraints[:target_cost_per_meal_cents].to_i / 100.0)
        constraints_text << "Budget indicatif d'environ #{target} € pour les ingrédients de ce repas : privilégie des produits simples et économiques"
      end
      
      if @constraints[:dietary_restrictions].present? && @constraints[:dietary_restrictions].any?
        constraints_text << "Restrictions : #{@constraints[:dietary_restrictions].join(', ')}"
      else
        constraints_text << "Aucune restriction alimentaire, tu peux inclure de la viande, du poisson et des fruits de mer"
      end

      if @constraints[:excluded_ingredients].present? && @constraints[:excluded_ingredients].any?
        constraints_text << "Ingrédients à éviter : #{@constraints[:excluded_ingredients].join(', ')}"
      end

      "Génère une recette avec les contraintes suivantes : #{constraints_text.join('. ')}. RAPPEL : Ta réponse doit être UNIQUEMENT un objet JSON valide, sans aucun texte avant ou après. Évite de générer une soupe ou un potage si tu en as déjà généré récemment. IMPORTANT : Adapte PRÉCISÉMENT les quantités au nombre de personnes spécifié. Fournis ingredients en texte lisible et recipe_ingredients en tableau JSON structuré."
    end

    def user_context_prompt
      parts = []

      if @user_context[:liked_recipes].present?
        parts << "L'utilisateur a recemment aime ces recettes : #{@user_context[:liked_recipes].join(', ')}. Propose des variantes ou des plats similaires."
      end

      if @user_context[:disliked_recipes].present?
        parts << "L'utilisateur n'a PAS aime : #{@user_context[:disliked_recipes].join(', ')}. Evite ces types de plats."
      end

      if @user_context[:available_ingredients].present?
        parts << "L'utilisateur a ces ingredients disponibles : #{@user_context[:available_ingredients].join(', ')}. Priorise les recettes utilisant ces ingredients."
      end

      parts.join("\n")
    end

    def parse_response(content)
      # Essayer de nettoyer la réponse pour extraire uniquement le JSON
      content = content.strip
      
      # Si la réponse commence par un texte suivi d'un JSON, essayer d'extraire le JSON
      if content.include?('{') && content.include?('}')
        start_index = content.index('{')
        end_index = content.rindex('}')
        if start_index && end_index && end_index > start_index
          content = content[start_index..end_index]
        end
      end
      
      begin
        json_response = JSON.parse(content)
        
        # Convertir les instructions en chaîne de caractères si c'est un tableau
        if json_response["instructions"].is_a?(Array)
          json_response["instructions"] = json_response["instructions"].join("\n")
        end

        json_response["ingredients"] = normalize_ingredients_text(json_response["ingredients"])
        structured_ingredients = normalize_recipe_ingredients(json_response)
        
        Recipe.new(
          title: json_response["title"],
          description: json_response["description"],
          ingredients: json_response["ingredients"],
          instructions: json_response["instructions"],
          servings: json_response["servings"],
          preparation_time: json_response["preparation_time"],
          cooking_time: json_response["cooking_time"],
          difficulty: json_response["difficulty"],
          seasonal_ingredients_used: json_response["seasonal_ingredients_used"],
          recipe_ingredients: structured_ingredients,
          generated_at: Time.current
        )
      rescue JSON::ParserError => e
        Rails.logger.error "Erreur de parsing JSON : #{e.message}"
        Rails.logger.error "Contenu reçu : #{content}"
        raise GenerationError, "Format de réponse invalide"
      end
    end

    def normalize_ingredients_text(value)
      if value.is_a?(Array)
        value.join("\n")
      elsif value.is_a?(Hash)
        value.map { |ingredient, quantity| "#{quantity} #{ingredient}" }.join("\n")
      elsif value.is_a?(String) && !value.include?("\n")
        value.split(/,\s*/).map(&:strip).join("\n")
      else
        value
      end
    end

    def normalize_recipe_ingredients(json_response)
      structured = json_response["recipe_ingredients"]
      return normalize_structured_ingredients(structured) if structured.present?

      IngredientParser.parse_lines(json_response["ingredients"])
    end

    def normalize_structured_ingredients(ingredients)
      Array(ingredients).filter_map do |ingredient|
        next unless ingredient.is_a?(Hash)

        raw = ingredient["raw"].presence || ingredient["name"]
        parsed = IngredientParser.parse_line(raw)
        name = ingredient["name"].presence || parsed[:name]

        {
          raw: raw,
          quantity: ingredient["quantity"].presence&.to_f || parsed[:quantity],
          unit: ingredient["unit"].presence || parsed[:unit],
          name: IngredientParser.normalize_name(name),
          category: ingredient["category"].presence || parsed[:category]
        }
      end
    end

    def api_error_details(error)
      response = error.respond_to?(:response) && error.response.is_a?(Hash) ? error.response : {}
      body = response[:body]
      body = JSON.parse(body) if body.is_a?(String)
      payload = body.is_a?(Hash) ? (body["error"] || body[:error] || {}) : {}

      {
        status: response[:status],
        code: payload["code"] || payload[:code] || payload["type"] || payload[:type]
      }
    rescue JSON::ParserError
      { status: response[:status], code: nil }
    end

    def raise_api_error(error, code:, retryable:)
      details = api_error_details(error)
      Rails.logger.error(
        "OpenAI recipe generation failed: class=#{error.class} status=#{details[:status]} code=#{code || 'unknown'}"
      )

      message = if code == "insufficient_quota"
        "Quota OpenAI épuisé"
      elsif retryable
        "Limite temporaire OpenAI atteinte"
      else
        "Service OpenAI indisponible"
      end

      raise GenerationError.new(message, code: code, retryable: retryable)
    end
  end
end
