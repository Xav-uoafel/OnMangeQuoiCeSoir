require Rails.root.join("lib/production_environment_validator")

if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  ProductionEnvironmentValidator.new.validate!
end
