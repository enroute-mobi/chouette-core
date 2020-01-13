# coding: utf-8
source 'https://rubygems.org'

# Use https for github
git_source(:github) { |name| "https://github.com/#{name}.git" }
git_source(:en_route) { |name| "https://bitbucket.org/enroute-mobi/#{name}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.4'

# Use SCSS for stylesheets
gem 'sassc-rails'

# FIXME See CHOUETTE-188
gem 'sassc', '2.1.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7.2'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'

gem 'sprockets', '~> 3.7.2'

# Webpacker
gem 'webpacker', '3.2.1'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# Select2 for pretty select boxes w. autocomplete
gem 'select2-rails', '~> 4.0', '>= 4.0.3'

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring', group: :development
# ActiveRecord associations on top of PostgreSQL arrays
gem 'has_array_of', en_route: 'has_array_of'

gem 'rails-observers'

# Use SeedBank for spliting seeds
gem 'seedbank', '0.4.0'

gem 'faraday_middleware'
gem 'faraday', '~> 0.11'

gem 'therubyracer', '~> 0.12'
gem 'pg'

gem 'activerecord-postgis-adapter'
gem 'polylines'
gem 'bulk_insert'

# Codifligne API
gem 'codifligne', en_route: 'ilico-api'
# ICar API
gem 'icar', en_route: 'icar-api'

# Authentication
gem 'devise'
gem 'devise_cas_authenticatable'
gem 'devise-encryptable'
gem 'devise_invitable'

# Authorization
gem 'pundit'

# Map, Geolocalization
gem 'map_layers', '0.0.4'
gem 'rgeo'
gem 'rgeo-proj4', en_route: 'rgeo-proj4'
# gem 'georuby-ext'
gem 'geokit'
gem 'georuby', '2.3.0' # Fix version for georuby-ext because api has changed
gem 'ffi-geos'

gem 'ffi', '> 1.9.24'
gem 'mimemagic'

# User interface
gem 'language_engine', '0.0.9', en_route: 'language_engine'
gem 'calendar_helper', '0.2.5'
gem 'cocoon'
gem 'slim-rails'
gem 'formtastic'
gem 'simple_form'
gem 'font-awesome-sassc'
gem 'will_paginate-bootstrap'
gem 'gretel'
gem 'country_select'
gem 'flag-icons-rails'
gem 'i18n-js'
gem 'clockpicker-rails'

# Format Output
gem 'json'
gem 'rubyzip', '~> 1.3.0'
gem 'roo'

# Controller
gem 'inherited_resources'
gem 'responders'

# Model
gem 'will_paginate'
gem 'ransack'
#gem "squeel", github: 'activerecord-hackery/squeel'
gem 'active_attr'

gem 'sequel'

gem 'draper'

gem 'enumerize', '~> 2.1.2'
gem 'deep_cloneable'
gem 'acts-as-taggable-on'
gem 'nokogiri', '>= 1.10.4'

gem 'acts_as_list'
gem 'acts_as_tree'

gem 'rabl'
gem 'carrierwave', '~> 1.0'
gem 'rmagick'

gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'delayed_job_heartbeat_plugin'

gem 'whenever', en_route: 'whenever', require: false # '~> 0.9'
gem 'rake'
gem 'apartment', '~> 2.2.0'
gem 'aasm'
gem 'puma', '~> 4.3.0'

# Cache
gem 'redis-rails'

gem 'gtfs', en_route: 'gtfs'

gem 'ddtrace'

group :development do
  gem 'rails-erd'
  gem 'license_finder'
  gem 'bundler-audit'
  gem 'spring-commands-rspec'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'derailed_benchmarks'
  gem 'stackprof'

  gem 'bummr'
end

group :test do
  gem 'email_spec'
  gem 'htmlbeautifier'
  gem 'timecop'
  gem 'rspec-snapshot'
  gem 'rails-controller-testing'
  gem 'fuubar'

  gem 'rspec_junit_formatter'
  gem 'codacy-coverage', require: false
end

group :test, :development do
  gem 'rspec-rails'
  gem 'capybara', '~> 3.15.0'
  gem 'database_cleaner'
  gem 'poltergeist'

  gem 'webmock'
  gem 'shoulda-matchers'

  gem 'parallel_tests'

  gem 'letter_opener'
  gem 'letter_opener_web', '~> 1.0'

  gem 'fabrication', '~> 2.14.1'
  gem 'ffaker', '~> 2.1.0'
  gem 'faker'

  gem 'factory_girl_rails', '~> 4.0'

  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry-byebug'

  gem "teaspoon-jasmine"
  gem "phantomjs"
end

# I18n
gem 'rails-i18n'
gem 'devise-i18n'
gem 'i18n-tasks'

# Rails Assets
source 'https://rails-assets.org' do
  gem 'rails-assets-footable', '~> 2.0.3'

  # Use twitter bootstrap resources
  gem 'rails-assets-bootstrap-sass-official', '~> 3.3.0'
  gem 'rails-assets-respond'
  gem 'rails-assets-jquery-tokeninput', '~> 1.7.0'

  gem 'rails-assets-modernizr', '~> 2.0.6'
end

gem 'activerecord-nulldb-adapter', require: (ENV['RAILS_DB_ADAPTER'] == 'nulldb')

gem 'google-cloud-storage', '> 1.4.0'
gem 'net-sftp', '~> 2.1'
