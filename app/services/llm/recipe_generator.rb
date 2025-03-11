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
          sleep(2) 
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
        
        IMPORTANT : 
        1. Ta réponse DOIT être UNIQUEMENT un objet JSON valide, sans aucun texte avant ou après.
        2. Ne réponds pas avec du texte, des explications ou des excuses.
        3. Génère des recettes VARIÉES (plats principaux, entrées, desserts) et en minimisant le nombre de soupes ou potages maximum deux fois par semaine et les plats similaires par exemple un poulet roti aux légumes de saisin et un poulet roti aux herbes de provence.
        4. Si aucune restriction alimentaire n'est spécifiée, tu peux inclure de la viande, du poisson et des fruits de mer.
        5. Adapte PRÉCISÉMENT les quantités d'ingrédients au nombre de personnes spécifié. Par exemple, pour 4 personnes : "400g de viande", pour 2 personnes : "200g de viande".
        6. Si aucun nombre de personnes n'est spécifié, prévois la recette pour 4 personnes par défaut.
        7. Pour les ingrédients, fournis une LISTE SIMPLE (pas un objet ou dictionnaire) avec un ingrédient par ligne, au format "quantité + nom de l'ingrédient" (ex: "400g de bœuf", "2 oignons", "1 cuillère à soupe d'huile d'olive").
        
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
          "seasonal_ingredients_used": ["liste", "des", "ingrédients", "de", "saison", "utilisés"]
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
      
      if @constraints[:dietary_restrictions].present? && @constraints[:dietary_restrictions].any?
        constraints_text << "Restrictions : #{@constraints[:dietary_restrictions].join(', ')}"
      else
        constraints_text << "Aucune restriction alimentaire, tu peux inclure de la viande, du poisson et des fruits de mer"
      end

      if @constraints[:excluded_ingredients].present? && @constraints[:excluded_ingredients].any?
        constraints_text << "Ingrédients à éviter : #{@constraints[:excluded_ingredients].join(', ')}"
      end

      "Génère une recette avec les contraintes suivantes : #{constraints_text.join('. ')}. RAPPEL : Ta réponse doit être UNIQUEMENT un objet JSON valide, sans aucun texte avant ou après. Évite de générer une soupe ou un potage si tu en as déjà généré récemment. IMPORTANT : Adapte PRÉCISÉMENT les quantités au nombre de personnes spécifié. Pour les ingrédients, fournis une LISTE SIMPLE (pas un objet ou dictionnaire) avec un ingrédient par ligne."
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
        
        # Convertir les ingrédients en chaîne de caractères si c'est un tableau ou un hash
        if json_response["ingredients"].is_a?(Array)
          json_response["ingredients"] = json_response["ingredients"].join("\n")
        elsif json_response["ingredients"].is_a?(Hash)
          # Si les ingrédients sont un hash, le convertir en liste
          ingredients_list = json_response["ingredients"].map do |ingredient, quantity|
            "#{quantity} #{ingredient}"
          end
          json_response["ingredients"] = ingredients_list.join("\n")
        elsif json_response["ingredients"].is_a?(String) && !json_response["ingredients"].include?("\n")
          # Si les ingrédients sont une chaîne sans sauts de ligne, essayer de les formater
          ingredients = json_response["ingredients"].split(/,\s*/).map(&:strip)
          json_response["ingredients"] = ingredients.join("\n")
        end
        
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
end 