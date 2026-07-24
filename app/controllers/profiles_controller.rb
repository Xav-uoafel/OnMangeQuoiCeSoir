class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to authenticated_root_path, notice: 'Profil mis à jour avec succès !'
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :household_size, :preferred_max_prep_time,
      dietary_restrictions: [], excluded_ingredients: []
    ).tap do |p|
      p[:dietary_restrictions] = Array(p[:dietary_restrictions]).reject(&:blank?)
      p[:excluded_ingredients] = parse_excluded_ingredients(params[:user][:excluded_ingredients_text])
    end
  end

  def parse_excluded_ingredients(text)
    return [] if text.blank?

    text.split(",").map(&:strip).reject(&:blank?)
  end
end
