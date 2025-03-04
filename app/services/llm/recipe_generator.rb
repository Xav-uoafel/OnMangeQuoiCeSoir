# frozen_string_literal: true

require 'openai'

module LLM
  class RecipeGenerator
    class GenerationError < StandardError; end

    def initialize(constraints)
      @constraints = constraints
      @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
    end

    def generate_recipe
      retries = 3
      begin
        response = @client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: user_prompt }
            ],
            temperature: 0.7
          }
        )

        parse_response(response.dig("choices", 0, "message", "content"))
      rescue OpenAI::Error => e
        if e.message.include?("429") && retries > 0
          retries -= 1
          sleep(2) # Attendre avant de réessayer
          retry
        else
          Rails.logger.error "Erreur OpenAI : #{e.message}"
          Rails.logger.error "Prompt système : #{system_prompt}"
          Rails.logger.error "Prompt utilisateur : #{user_prompt}"
          raise GenerationError, "Erreur lors de la génération de la recette : #{e.message}"
        end
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
        
        Génère une recette au format JSON avec les champs suivants :
        {
          "title": "Titre de la recette",
          "description": "Description courte",
          "ingredients": "Liste des ingrédients",
          "instructions": "Instructions étape par étape",
          "servings": nombre de portions,
          "preparation_time": temps en minutes,
          "cooking_time": temps en minutes,
          "difficulty": "Facile|Intermédiaire|Difficile",
          "seasonal_ingredients_used": ["liste", "des", "ingrédients", "de", "saison", "utilisés"]
        }
      PROMPT
    end

    def user_prompt
      constraints_text = []
      constraints_text << "Pour #{@constraints[:servings]} personnes" if @constraints[:servings].present?
      constraints_text << "Temps de préparation maximum : #{@constraints[:max_preparation_time]} minutes" if @constraints[:max_preparation_time].present?
      
      if @constraints[:dietary_restrictions].present?
        constraints_text << "Restrictions : #{@constraints[:dietary_restrictions].join(', ')}"
      end

      if @constraints[:excluded_ingredients].present?
        constraints_text << "Ingrédients à éviter : #{@constraints[:excluded_ingredients].join(', ')}"
      end

      "Génère une recette avec les contraintes suivantes : #{constraints_text.join('. ')}."
    end

    def parse_response(content)
      json_response = JSON.parse(content)
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
        generated_at: Time.current
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Erreur de parsing JSON : #{e.message}"
      Rails.logger.error "Contenu reçu : #{content}"
      raise GenerationError, "Format de réponse invalide"
    end
  end
end 