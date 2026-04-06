class ApplicationController < ActionController::Base
  before_action :redirect_to_onboarding

  private

  def redirect_to_onboarding
    return unless user_signed_in?
    return if current_user.onboarding_completed?
    return if devise_controller?
    return if is_a?(OnboardingsController)

    redirect_to onboarding_path
  end
end
