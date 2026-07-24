class HealthController < ApplicationController
  skip_before_action :redirect_to_onboarding

  class_attribute :database_check, default: -> { ActiveRecord::Base.connection.select_value("SELECT 1") }

  def show
    response.headers["Cache-Control"] = "no-store"
    self.class.database_check.call

    render json: { status: "ok", checks: { database: "up" } }
  rescue StandardError => e
    Rails.error.report(e, handled: true)
    render json: { status: "unavailable", checks: { database: "down" } }, status: :service_unavailable
  end
end
