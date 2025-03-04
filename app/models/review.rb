class Review < ApplicationRecord
    belongs_to :recipe
    belongs_to :user
    # Ajoute éventuellement des validations, par exemple :
    validates :rating, presence: true, 
              numericality: { 
                only_integer: true,
                greater_than_or_equal_to: 1, 
                less_than_or_equal_to: 5,
                message: "doit être entre 1 et 5" 
              }
    validates :comment, presence: { message: "Le commentaire ne peut pas être vide" },
              length: { minimum: 10, maximum: 500, 
                       too_short: "doit faire au moins %{count} caractères",
                       too_long: "ne doit pas dépasser %{count} caractères" }
    
    # Empêcher les utilisateurs de poster plusieurs reviews sur la même recette
    validates :user_id, uniqueness: { 
      scope: :recipe_id,
      message: "a déjà commenté cette recette"
    }

    def self.average_rating
      average(:rating).to_f.round(1)
    end
end
  