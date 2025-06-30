# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( base.css es6_browserified/*.js helpers/*.js filters/*.js)
Rails.application.config.assets.precompile += %w( api.css )
Rails.application.config.assets.precompile += %w( OpenLayers/maps_backgrounds.js )
Rails.application.config.assets.precompile += %w( language_engine/*_flag.png )

Rails.application.config.assets.configure do |env|
  paths_to_exclude = %w[
    actioncable
    actiontext
    activestorage
  ].map { |g| Gem.loaded_specs[g].full_gem_path }
  env.config = env.hash_reassoc(env.config, :paths) do |paths|
    paths.delete_if { |p| paths_to_exclude.any? { |e| p.start_with?(e) } }
  end
end
