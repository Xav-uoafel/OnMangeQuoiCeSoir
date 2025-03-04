# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")
Rails.application.config.assets.paths << Rails.root.join("app/javascript")

# Precompile additional assets.
Rails.application.config.assets.precompile += %w( 
  tailwind.css
  application.css
  application.js
  controllers/*.js
  controllers/application.js
  controllers/hello_controller.js
  controllers/index.js
)

# Enable the asset pipeline
Rails.application.config.assets.enabled = true

# Compile assets during asset compilation
Rails.application.config.assets.compile = true

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
