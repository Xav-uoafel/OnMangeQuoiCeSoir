class ApplicationController < ActionController::Base
  before_action :redirect_to_onboarding

  def self.database_rate_limit(to:, within:, scope:, only:)
    before_action(only: only) do
      enforce_database_rate_limit(scope: scope, limit: to, period: within)
    end
  end

  private

  def enforce_database_rate_limit(scope:, limit:, period:)
    return unless user_signed_in?

    result = RequestRateLimiter.new(
      scope: scope,
      identity: current_user.id,
      limit: limit,
      period: period
    ).call
    return if result.allowed?

    response.set_header("Retry-After", result.retry_after.to_s)
    response.set_header("Cache-Control", "no-store")
    @retry_after_seconds = result.retry_after
    Rails.logger.warn "Rate limit exceeded: scope=#{scope} user_id=#{current_user.id}"
    render "errors/too_many_requests", status: :too_many_requests
  end

  def redirect_to_onboarding
    return unless user_signed_in?
    return if current_user.onboarding_completed?
    return if devise_controller?
    return if is_a?(OnboardingsController)

    redirect_to onboarding_path
  end
end
