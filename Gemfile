# coding: utf-8
source 'https://rubygems.org'

# Use https for github
git_source(:github) { |name| "https://github.com/#{name}.git" }
git_source(:af83) { |name| "git@github.com:af83/#{name}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.8'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7.2'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# Webpacker
gem 'webpacker', '3.2.1'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 3.1.4' # Update to v4 for Rails 4.2
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Select2 for pretty select boxes w. autocomplete
gem 'select2-rails', '~> 4.0', '>= 4.0.3'

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring', group: :development
# ActiveRecord associations on top of PostgreSQL arrays
gem 'has_array_of', af83: 'has_array_of'

# Track changes to your models' data. Good for auditing or versioning.
gem 'paper_trail'

gem 'rails-observers'

# Use SeedBank for spliting seeds
gem 'seedbank'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# API Rest
gem 'sawyer', '~> 0.6.0'
gem 'faraday_middleware', '~> 0.9.1'
gem 'faraday', '~> 0.9.1'

platforms :ruby do
  gem 'therubyracer', '~> 0.12'
  gem 'pg'
  #gem 'sqlite3'
end

gem 'activerecord-postgis-adapter', "~> 3.0.0"
gem 'polylines'
gem 'activerecord-nulldb-adapter', require: false

# Codifligne API
gem 'codifligne', af83: 'stif-codifline-api'
# Reflex API
gem 'reflex', af83: 'stif-reflex-api'

# Authentication
gem 'devise', '~> 3.5.4'
gem 'devise_cas_authenticatable'
gem 'devise-encryptable'
gem 'devise_invitable'

# Authorization
gem 'pundit'

# Map, Geolocalization
gem 'map_layers', '0.0.4'
gem 'rgeo', '~> 0.5.2'
gem 'georuby-ext', '0.0.5'
gem 'georuby', '2.3.0' # Fix version for georuby-ext because api has changed

gem 'mimemagic'

# User interface
gem 'language_engine', github: 'af83/language_engine'
gem 'calendar_helper', '0.2.5'
gem 'cocoon'
gem 'slim-rails', '~> 3.1'
gem 'formtastic', '3.1.5'
gem 'RedCloth', '~> 4.3.0'
gem 'simple_form', '~> 3.1.0'
gem 'font-awesome-sass', '~> 4.7'
gem 'will_paginate-bootstrap'
gem 'gretel'
gem 'country_select'
gem 'flag-icons-rails'
gem 'i18n-js'

# Format Output
gem 'json'
gem 'rubyzip'
gem 'roo'

# Controller
gem 'inherited_resources'
gem 'responders'
gem 'google-analytics-rails'

# Model
gem 'will_paginate'
gem 'ransack'
#gem "squeel", github: 'activerecord-hackery/squeel'
gem 'active_attr'

gem 'sequel'

gem 'draper'

gem 'enumerize', '~> 2.1.2'
gem 'deep_cloneable', '~> 2.0.0'
gem 'acts-as-taggable-on', '~> 4.0.0'

gem 'acts_as_list', '~> 0.6.0'
gem 'acts_as_tree', '~> 2.1.0', require: 'acts_as_tree'

gem 'rabl'
gem 'carrierwave', '~> 1.0'

gem 'sidekiq'
gem 'sinatra'
gem 'whenever', github: 'af83/whenever', require: false # '~> 0.9'
gem 'rake'
gem 'devise-async'
gem 'apartment', '~> 1.0.0'
gem 'aasm'
gem 'activerecord-nulldb-adapter'
gem 'puma', '~> 3.10.0'

gem 'newrelic_rpm'
gem 'letter_opener'

group :development do
  gem 'capistrano', '2.13.5'
  gem 'capistrano-ext'
  #gem 'capistrano-npm', require: false
  # Issue #3017 Requires ruby_dep which requires ruby > 2.2.3
  # gem 'guard'
  # gem 'guard-rspec', "~> 4.5.0"
  gem 'rails-erd'
  # MetaRequest is incompatible with rgeo-activerecord
  # gem 'meta_request'
  gem 'quiet_assets'
  gem 'license_finder'
  gem 'bundler-audit'
  gem 'spring-commands-rspec'
  gem 'dbshell-rails'
  gem 'rack-livereload'

  platforms :ruby_20, :ruby_21, :ruby_22 do
    gem 'better_errors'
    gem 'binding_of_caller'
  end
end

group :test do
  gem 'email_spec'
  gem 'cucumber-rails', require: false
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
  gem 'htmlbeautifier'
  gem 'timecop'
  gem 'rspec-snapshot'
end

group :test, :development, :dev do
  gem 'fabrication', '~> 2.14.1'
  gem 'ffaker', '~> 2.1.0'
  gem 'faker'
end

group :test, :development do
  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.5.0'
  gem 'fakeweb'
  gem 'webmock'
  gem 'capybara', '~> 2.4.0'
  gem 'database_cleaner'
  gem 'poltergeist'
  gem 'launchy'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'rb-inotify', require: RUBY_PLATFORM.include?('linux') && 'rb-inotify'
  gem 'rb-fsevent', require: RUBY_PLATFORM.include?('darwin') && 'rb-fsevent'
  gem 'transpec'
  gem 'shoulda-matchers', '~> 3.1'
  gem "teaspoon-jasmine"
  gem "phantomjs"
end

group :production do
  gem 'SyslogLogger', require: 'syslog/logger'
  gem 'daemons'
end

# I18n
gem 'rails-i18n', '~> 4.0.0'
gem 'devise-i18n'
gem 'i18n-tasks'

# Rails Assets
source 'https://rails-assets.org' do
  gem 'rails-assets-footable', '~> 2.0.3'

  # Use twitter bootstrap resources
  gem 'rails-assets-bootstrap-sass-official', '~> 3.3.0'
  gem 'rails-assets-tagmanager', '~> 3.0.1.0'
  gem 'rails-assets-respond'
  gem 'rails-assets-jquery-tokeninput', '~> 1.7.0'

  gem 'rails-assets-modernizr', '~> 2.0.6'
end
