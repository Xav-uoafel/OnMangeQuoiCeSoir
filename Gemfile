source "https://rubygems.org"

ruby "3.4.2"


# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails", "~> 3.4.2"

# Use PostgreSQL as the database for Active Record
gem "pg", "~> 1.5"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 7.2", ">= 7.2.1"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Devise for authentication
gem "devise", ">= 5.0.4", "< 6"

# Use Tailwind CSS for styling
gem "tailwindcss-rails"


# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem 'dotenv-rails'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :development do
  gem "letter_opener_web", "~> 3.0"

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
# Stimulus
gem 'stimulus-rails'
# Importmap
gem 'importmap-rails'
# JavaScript
gem 'turbo-rails'

gem "sprockets", "~> 4.2"

# use openai to generate recipes
gem 'ruby-openai'

# HTTP client used by the public Open Prices integration
gem "faraday", "~> 2.14", ">= 2.14.3"

# Background jobs
gem 'solid_queue'

# Image processing (Active Storage variants)
gem "image_processing", "~> 1.2"

# Persistent object storage in production
gem "aws-sdk-s3", require: false
