class RecipesController < ApplicationController
    before_action :authenticate_user!, except: [:index, :show]
    before_action :set_recipe, only: [:show, :edit, :update, :destroy, :mark_cooked]
    before_action :authorize_recipe, only: [:edit, :update, :destroy]

    def index
        @recipes = Recipe.all.includes(:reviews)
    end

    def new
        @recipe = Recipe.new
    end

    def show
        @review = Review.new
        @reviews = @recipe.reviews.includes(:user)
    end

    def create
        @recipe = current_user.recipes.build(recipe_params)

        if @recipe.save
            redirect_to @recipe, notice: I18n.t('flash.recipe_created')
        else
            flash.now[:error] = @recipe.errors.full_messages.to_sentence
            render :new, status: :unprocessable_entity
        end
    end

    def edit
    end

    def update
        if @recipe.update(recipe_params)
            redirect_to @recipe, notice: I18n.t('flash.recipe_updated')
        else
            flash.now[:error] = @recipe.errors.full_messages.to_sentence
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @recipe.destroy
        redirect_to recipes_path, notice: I18n.t('flash.recipe_deleted')
    end

    def mark_cooked
      cooked = current_user.cooked_recipes.find_or_initialize_by(recipe: @recipe)
      cooked.cooked_on = Date.current
      cooked.liked = params[:liked] == "true" ? true : (params[:liked] == "false" ? false : nil)

      if cooked.save
        redirect_to @recipe, notice: 'Recette enregistree !'
      else
        redirect_to @recipe, alert: 'Erreur lors de l\'enregistrement.'
      end
    end

    private

    def set_recipe
        @recipe = Recipe.find(params[:id])
    end

    def recipe_params
        params.require(:recipe).permit(
            :title, :description, :ingredients, :instructions,
            :servings, :preparation_time, :cooking_time, :difficulty
        )
    end

    def authorize_recipe
        unless @recipe.user == current_user
            render status: :forbidden, plain: "Non autorisé"
        end
    end
end
