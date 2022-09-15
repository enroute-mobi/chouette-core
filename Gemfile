source 'https://rubygems.org'

# Use https for github
git_source(:github) { |name| "https://github.com/#{name}.git" }
git_source(:en_route) { |name| "https://bitbucket.org/enroute-mobi/#{name}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.8.1'

gem 'health_check', '>= 3.1.0'

group :production do
  gem 'mini_racer'
end

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 2.7.2'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '>= 5.0.0'

gem 'sprockets', '~> 3.7.2'

# Webpacker
gem 'webpacker', '6.0.0.beta.7'

# Use jquery as the JavaScript library
gem 'jquery-rails', '>= 4.4.0'
gem 'jquery-ui-rails', '>= 6.0.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# Select2 for pretty select boxes w. autocomplete
gem 'select2-rails', '~> 4.0', '>= 4.0.3'

# ActiveRecord associations on top of PostgreSQL arrays
gem 'has_array_of', en_route: 'has_array_of'

gem 'rails-observers'
# gem 'wisper', '2.0.0'

# Use SeedBank for spliting seeds
gem 'seedbank', '0.4.0'

gem 'faraday_middleware'
gem 'faraday'

gem 'pg'

gem 'activerecord-postgis-adapter', '~> 5.2.3'
gem 'postgres-copy', '>= 1.5.0'

gem 'polylines'
gem 'bulk_insert'

gem 'graphql', '~> 1.12.19'

# Codifligne API
gem 'codifligne', en_route: 'ilico-api'
# ICar API
gem 'icar', en_route: 'icar-api'

# Authentication
gem 'devise', '>= 4.8.1'
gem 'devise_cas_authenticatable', '>= 1.10.4'
gem 'devise-encryptable', '>= 0.2.0'
gem 'devise_invitable', '>= 2.0.6'

# Authorization
gem 'pundit'

# Map, Geolocalization
gem 'rgeo'
gem 'rgeo-proj4'
gem 'geokit'
gem 'georuby', '2.3.0' # Fix version for georuby-ext because api has changed

gem 'mimemagic', '>= 0.4.3'

# User interface
gem 'language_engine', en_route: 'language_engine'
gem 'calendar_helper', '0.2.5'
gem 'cocoon'
gem 'slim-rails', '>= 3.3.0'
gem 'simple_form', '>= 5.1.0'
gem 'will_paginate-bootstrap'
gem 'gretel', '>= 4.4.0'
gem 'country_select'
gem 'i18n-js'
gem 'font_awesome5_rails', '>= 1.5.0'

# Format Output
gem 'json'
gem 'rubyzip'
gem 'roo', '>= 2.8.3'

# Controller
gem 'inherited_resources', '>= 1.13.1'
gem 'responders', '>= 3.0.1'

gem "lograge", ">= 0.11.2"

# Model
gem 'will_paginate'
gem 'ransack'
gem 'active_attr', '>= 0.15.4'

gem 'draper', '>= 4.0.2'

gem 'enumerize'
gem 'deep_cloneable'
gem 'acts-as-taggable-on'
gem 'nokogiri', '>= 1.13.2'

gem 'acts_as_list'
gem 'acts_as_tree'

gem 'rabl'
gem 'carrierwave', '~> 1.3.2'
gem 'carrierwave-google-storage', github: 'metaware/carrierwave-google-storage'
gem 'rmagick'

gem 'delayed_job_active_record'
gem 'delayed_job_heartbeat_plugin'
gem 'delayed_cron_job'

gem 'whenever', en_route: 'whenever', require: false
gem 'rake'
gem 'apartment'
gem 'aasm'
gem 'puma', '>= 5.6.4'
gem 'postgresql_cursor'

# CSS styled emails without the hassle.
gem 'premailer-rails', '>= 1.11.1'

# Redis session management
gem 'redis-actionpack', '>= 5.3.0'

gem 'gtfs', en_route: 'gtfs'
gem 'netex', en_route: 'netex'
gem 'rgeo-shapefile'
gem 'ara-file', '>= 0.1.2', en_route: 'ara-file'
gem 'neptune', en_route: 'neptune'

# Monitoring
gem 'ddtrace'
gem 'sentry-delayed_job'
gem 'sentry-ruby'
gem 'sentry-rails'

gem 'nest', en_route: 'nest'

group :development do
  gem 'rails-erd'
  gem 'license_finder'
  gem 'bundler-audit'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'derailed_benchmarks'

  gem 'bummr'
  gem 'graphiql-rails', '>= 1.8.0'

  gem 'guard-rspec', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'email_spec'
  gem 'htmlbeautifier'
  gem 'timecop'
  gem 'rspec-snapshot'
  gem 'rails-controller-testing', '>= 1.0.5'
  gem 'fuubar'
  gem 'rspec-benchmark'
  gem 'pundit-matchers', '>= 1.7.0'

  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
end

group :test, :development do
  gem 'rspec-rails', '>= 5.1.0'
  gem 'capybara', '~> 3.15.1'
  gem 'database_cleaner'
  gem 'poltergeist', '>= 1.18.1'
  gem 'stackprof'

  gem 'webmock'
  gem 'shoulda-matchers'

  gem 'parallel_tests'

  gem 'letter_opener'
  gem 'letter_opener_web', '~> 1.4', '>= 1.4.1'

  gem 'ffaker', '~> 2.1.0'
  gem 'faker'

  gem 'factory_bot_rails', '>= 6.2.0'

  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry-byebug'

  gem 'teaspoon-jasmine', '>= 2.9.1'
  gem 'phantomjs'

  gem 'dotenv-rails', '>= 2.7.6'
end

# I18n
gem 'rails-i18n', '>= 5.1.3'
gem 'devise-i18n', '>= 1.10.2'
gem 'i18n-tasks', '>= 0.9.37'

# Rails Assets
source 'https://rails-assets.org' do
  # Use twitter bootstrap resources
  gem 'rails-assets-bootstrap-sass-official', '~> 3.3.0'
  gem 'rails-assets-respond'
end

gem 'activerecord-nulldb-adapter', require: (ENV['RAILS_DB_ADAPTER'] == 'nulldb')

gem 'google-cloud-storage', '> 1.4.0'
gem 'net-sftp'
