class HomeController < ApplicationController
  def index
    @recipes = Recipe.includes(:reviews).order(created_at: :desc).limit(6)
  end

  def offline
    render layout: false
  end
end
