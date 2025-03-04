class RecipesController < ApplicationController
    before_action :authenticate_user!, except: [:index, :show]
    before_action :set_recipe, only: [:show, :edit, :update, :destroy]
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
