# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
Rails.application.config.assets.precompile += %w( rails.js )
Rails.application.config.assets.precompile += %w( redmond/jquery-ui.css )
Rails.application.config.assets.precompile += %w( redmond/jquery-ui.min.css )
Rails.application.config.assets.precompile += %w( redmond/theme.css )
Rails.application.config.assets.precompile += %w( jquery-ui.min.js )
Rails.application.config.assets.precompile += %w( jquery.js )
# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
