require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Production secrets are supplied by the platform environment, not encrypted files in the image.
  config.require_master_key = false

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Use an explicit service in production so uploads are not silently ephemeral.
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :solid_queue
  # config.active_job.queue_name_prefix = "onmangequoi_production"

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true

  app_host = ENV.fetch("APP_HOST", "localhost")
  config.action_mailer.default_url_options = { host: app_host, protocol: "https" }

  smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS", "localhost"),
    port: ENV.fetch("SMTP_PORT", 587),
    domain: ENV.fetch("SMTP_DOMAIN", app_host),
    enable_starttls_auto: ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true") == "true"
  }
  if ENV["SMTP_USERNAME"].present?
    smtp_settings.merge!(
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain")
    )
  end
  config.action_mailer.smtp_settings = smtp_settings

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts << app_host.split(":").first
  config.host_authorization = {
    exclude: ->(request) { request.path.in?(%w[/up /health]) }
  }
end
