class HomeController < ApplicationController
  def index
    @recipes = Recipe.order(created_at: :desc).limit(6)
  end
end 