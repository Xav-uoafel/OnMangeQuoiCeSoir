require "test_helper"

class ProductionEnvironmentValidatorTest < ActiveSupport::TestCase
  test "accepts a database URL and local persistent storage" do
    assert_nil ProductionEnvironmentValidator.new(valid_environment).validate!
  end

  test "requires explicit database settings when DATABASE_URL is absent" do
    environment = valid_environment.except("DATABASE_URL")

    error = assert_raises(ArgumentError) do
      ProductionEnvironmentValidator.new(environment).validate!
    end

    assert_includes error.message, "DATABASE_HOST"
    assert_includes error.message, "DATABASE_NAME"
    assert_includes error.message, "DATABASE_PASSWORD"
    assert_includes error.message, "DATABASE_USERNAME"
  end

  test "requires bucket settings for Amazon storage" do
    environment = valid_environment.merge("ACTIVE_STORAGE_SERVICE" => "amazon")

    error = assert_raises(ArgumentError) do
      ProductionEnvironmentValidator.new(environment).validate!
    end

    assert_includes error.message, "S3_BUCKET"
    assert_includes error.message, "S3_REGION"
  end

  test "rejects an unknown storage service" do
    environment = valid_environment.merge("ACTIVE_STORAGE_SERVICE" => "temporary")

    error = assert_raises(ArgumentError) do
      ProductionEnvironmentValidator.new(environment).validate!
    end

    assert_includes error.message, "amazon ou local"
  end

  test "requires complete AWS credentials when static credentials are configured" do
    environment = valid_environment.merge("AWS_ACCESS_KEY_ID" => "access-key")

    error = assert_raises(ArgumentError) do
      ProductionEnvironmentValidator.new(environment).validate!
    end

    assert_includes error.message, "AWS_SECRET_ACCESS_KEY"
  end

  test "requires complete SMTP credentials when authentication is configured" do
    environment = valid_environment.merge("SMTP_USERNAME" => "mailer")

    error = assert_raises(ArgumentError) do
      ProductionEnvironmentValidator.new(environment).validate!
    end

    assert_includes error.message, "SMTP_PASSWORD"
  end

  private

  def valid_environment
    {
      "ACTIVE_STORAGE_SERVICE" => "local",
      "APP_HOST" => "app.example.com",
      "DATABASE_URL" => "postgresql://user:password@database/app",
      "MAILER_FROM" => "contact@example.com",
      "SECRET_KEY_BASE" => "a" * 64,
      "SMTP_ADDRESS" => "smtp.example.com"
    }
  end
end
