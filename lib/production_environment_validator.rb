class ProductionEnvironmentValidator
  REQUIRED_VARIABLES = %w[ACTIVE_STORAGE_SERVICE APP_HOST MAILER_FROM SECRET_KEY_BASE SMTP_ADDRESS].freeze
  DATABASE_VARIABLES = %w[DATABASE_HOST DATABASE_NAME DATABASE_PASSWORD DATABASE_USERNAME].freeze
  AMAZON_VARIABLES = %w[S3_BUCKET S3_REGION].freeze
  AWS_CREDENTIALS = %w[AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY].freeze
  SMTP_CREDENTIALS = %w[SMTP_PASSWORD SMTP_USERNAME].freeze
  STORAGE_SERVICES = %w[amazon local].freeze

  def initialize(environment = ENV)
    @environment = environment
  end

  def validate!
    validate_storage_service!

    missing = missing_variables(REQUIRED_VARIABLES)
    missing.concat(missing_variables(DATABASE_VARIABLES)) unless present?("DATABASE_URL")
    missing.concat(missing_variables(AMAZON_VARIABLES)) if value("ACTIVE_STORAGE_SERVICE") == "amazon"
    missing.concat(missing_variables(AWS_CREDENTIALS)) if partially_configured?(AWS_CREDENTIALS)
    missing.concat(missing_variables(SMTP_CREDENTIALS)) if smtp_credentials_partially_configured?

    return if missing.empty?

    raise ArgumentError, "Configuration production incomplète : #{missing.uniq.sort.join(', ')}"
  end

  private

  attr_reader :environment

  def missing_variables(names)
    names.reject { |name| present?(name) }
  end

  def present?(name)
    value(name).present?
  end

  def validate_storage_service!
    return unless present?("ACTIVE_STORAGE_SERVICE")
    return if value("ACTIVE_STORAGE_SERVICE").in?(STORAGE_SERVICES)

    raise ArgumentError, "Configuration production invalide : ACTIVE_STORAGE_SERVICE doit valoir amazon ou local"
  end

  def partially_configured?(names)
    names.any? { |name| present?(name) } && names.any? { |name| !present?(name) }
  end

  def smtp_credentials_partially_configured?
    partially_configured?(SMTP_CREDENTIALS)
  end

  def value(name)
    environment[name].to_s.strip
  end
end
