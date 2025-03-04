class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_recipe
  before_action :set_review, only: [:edit, :update, :destroy]
  before_action :authorize_review, only: [:update, :destroy]

  def create
    @review = @recipe.reviews.build(review_params.merge(user: current_user))
    
    if @review.save
      redirect_to @recipe, notice: I18n.t('flash.review_created')
    else
      @reviews = @recipe.reviews.includes(:user)
      render "recipes/show", status: :unprocessable_entity
    end
  end

  def edit
    authorize_review
  end

  def update
    if @review.update(review_params)
      redirect_to @recipe, notice: I18n.t('flash.review_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @review.user == current_user
      @review.destroy
      redirect_to @recipe, notice: I18n.t('flash.review_deleted')
    else
      render status: :forbidden, plain: "Non autorisé"
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find(params[:recipe_id])
  end

  def set_review
    @review = @recipe.reviews.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:comment, :rating)
  end

  def authorize_review
    unless @review.user == current_user
      render status: :forbidden, plain: "Non autorisé"
    end
  end
end
