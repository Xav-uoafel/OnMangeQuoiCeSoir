class OnboardingsController < ApplicationController
  before_action :authenticate_user!

  def show
    redirect_to authenticated_root_path unless current_user.needs_onboarding?
  end

  def update
    if current_user.update(onboarding_params.merge(onboarding_completed: true))
      redirect_to authenticated_root_path, notice: 'Bienvenue ! Votre profil est configuré.'
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def onboarding_params
    params.require(:user).permit(
      :household_size, :preferred_max_prep_time,
      dietary_restrictions: []
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
