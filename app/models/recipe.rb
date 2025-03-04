class Recipe < ApplicationRecord
    belongs_to :user
    has_many :reviews, dependent: :destroy

    validates :title, presence: { message: "Le titre est obligatoire" }, 
              length: { minimum: 3, maximum: 100 }
    validates :description, presence: { message: "La description est obligatoire" }, 
              length: { minimum: 10, maximum: 1000 }
    validates :ingredients, presence: { message: "Les ingrédients sont obligatoires" }
    validates :instructions, presence: { message: "Les instructions sont obligatoires" }
    validates :servings, presence: { message: "Le nombre de portions est obligatoire" }, 
              numericality: { only_integer: true, greater_than: 0, less_than: 51 }
    validates :preparation_time, presence: { message: "Le temps de préparation est obligatoire" },
              numericality: { only_integer: true, greater_than: 0, less_than: 1441 } # max 24h
    validates :cooking_time, presence: { message: "Le temps de cuisson est obligatoire" },
              numericality: { only_integer: true, greater_than: 0, less_than: 1441 }
    validates :difficulty, presence: { message: "Le niveau de difficulté est obligatoire" }, 
              inclusion: { in: %w[Facile Intermédiaire Difficile],
                         message: "Le niveau de difficulté doit être Facile, Intermédiaire ou Difficile" }
    validates :user, presence: { message: "La recette doit être attribuée à un utilisateur" }
    validates :generated_at, presence: { message: "La date de génération est obligatoire" }
    validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }, allow_nil: true

    before_validation :ensure_generated_at

    def average_rating
      reviews.average_rating
    end

    def total_reviews
      reviews.count
    end

    def seasonal_score
      return 0 if seasonal_ingredients_used.blank?
      
      current_seasonal = SeasonalIngredientsService.current
      all_seasonal = current_seasonal[:vegetables] + current_seasonal[:fruits]
      
      used_seasonal = seasonal_ingredients_used & all_seasonal
      (used_seasonal.size.to_f / ingredients_list.size * 100).round
    end

    private

    def ensure_generated_at
      self.generated_at ||= Time.current
    end

    def ingredients_list
      ingredients.split(/[,\n]/).map(&:strip)
    end
end
