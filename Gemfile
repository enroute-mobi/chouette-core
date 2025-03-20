source 'https://rubygems.org'

# Use https for github
git_source(:github) { |name| "https://github.com/#{name}.git" }
git_source(:en_route) { |name| "https://bitbucket.org/enroute-mobi/#{name}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.8.1'
gem 'bootsnap', require: false

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
gem 'jquery-rails', '>= 4.6.0'
gem 'jquery-ui-rails', '>= 6.0.1'
gem 'rabl' # must be before draper (https://enroute.atlassian.net/browse/CHOUETTE-4361?focusedCommentId=50586)

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
gem 'pg_search'
gem 'postgres-copy', '>= 1.7.2'

gem 'bulk_insert'

gem 'graphql'

# Authentication
gem 'devise', '>= 4.9.3'
gem 'devise_cas_authenticatable', '~> 1'
gem 'devise-encryptable', '>= 0.2.0'
gem 'devise_invitable', '>= 2.0.6'
gem 'devise_saml_authenticatable'

# Map, Geolocalization

gem 'rgeo'
gem 'rgeo-proj4'
gem 'geokit'
gem 'georuby'

gem 'mimemagic', '>= 0.4.3'

# User interface
gem 'bootstrap-sass', '3.4.1'
gem 'language_engine', en_route: 'language_engine'
gem 'calendar_helper', '0.2.5'
gem 'cocoon'
gem 'slim-rails', '>= 3.3.0'
gem 'simple_form', '~> 5.1.0'
gem 'will_paginate-bootstrap'
gem 'gretel', '>= 4.4.0'
gem 'country_select'
gem 'i18n-js'
gem 'font_awesome5_rails', '>= 1.5.0'

# Format Output
gem 'json'
gem 'rubyzip'

# Controller
gem 'inherited_resources', '>= 1.13.1'
gem 'responders', '>= 3.1.1'

gem 'rails_semantic_logger'

# Model
gem 'will_paginate'
gem 'ransack'
gem 'active_attr', '>= 0.15.4'

gem 'draper', '>= 4.0.2'

gem 'enumerize', '>= 2.8.1'
gem 'deep_cloneable'
gem 'nokogiri', '>= 1.14.3'

gem 'acts_as_list'
gem 'acts_as_tree'

gem 'carrierwave', '~> 1.3.2'
gem 'carrierwave-google-storage', github: 'metaware/carrierwave-google-storage'
gem 'rmagick'

gem 'delayed_job_active_record'
gem 'delayed_job_heartbeat_plugin'
gem 'delayed_cron_job'

gem 'rake'
gem 'ros-apartment', require: 'apartment'
gem 'aasm'
gem 'puma', '>= 5.6.4'
gem 'postgresql_cursor', '0.6.6' # See https://enroute.atlassian.net/browse/CHOUETTE-2938 for details

# CSS styled emails without the hassle.
gem 'premailer-rails', '>= 1.11.1'

# Redis session management
gem 'redis-actionpack', '>= 5.3.0'

gem 'gtfs', en_route: 'gtfs', branch: 'DATA-14-read-gtfs-bookingrules'
gem 'netex', en_route: 'netex'
gem 'rgeo-shapefile'
gem 'ara', '>= 3.0.0', en_route: 'ara-ruby'
gem 'neptune', en_route: 'neptune'

# Monitoring
gem 'ddtrace'
gem 'google-protobuf', '~> 3.0'
gem 'dogstatsd-ruby'
gem 'prometheus-client'

gem 'sentry-delayed_job'
gem 'sentry-ruby'
gem 'sentry-rails'

gem 'coverband', '~> 5.2.5', require: false

gem 'nest', en_route: 'nest'

group :development do
  gem 'license_finder'
  gem 'bundler-audit'
  gem 'better_errors'
  gem 'binding_of_caller' # optional dependency of better_errors
  gem 'derailed_benchmarks'

  gem 'i18n-tasks'
  gem 'listen' # dependency of i18n-js
  gem 'rubocop-rails', '>= 2.24.0', require: false
end

group :test do
  gem 'email_spec'
  gem 'htmlbeautifier'
  gem 'timecop'
  gem 'rspec-snapshot'
  gem 'rails-controller-testing', '>= 1.0.5'
  gem 'rspec-rails', '>= 5.1.0'
  gem 'capybara', '~> 3.15.1'
  gem 'database_cleaner'
  gem 'poltergeist', '>= 1.18.1'
  gem 'rspec-benchmark'
  # RSpec progress bar
  gem 'fuubar'
  gem 'nyan-cat-formatter'

  gem 'webmock'
  gem 'shoulda-matchers'
  gem 'with_model'
  gem 'factory_bot_rails', '~> 6.2.0' # Could not upgrade to another version without https://enroute.atlassian.net/browse/CHOUETTE-3190
  gem 'faker'

  gem 'teaspoon-jasmine', '>= 2.9.1'
  gem 'phantomjs'

  gem 'rspec_junit_formatter'
  gem 'simplecov', require: false
  gem 'simplecov-cobertura', require: false
end

group :test, :development do
  gem 'awesome_print' # dependency of rails_semantic_logger until rspec-snapshot requires its fork 'amazing_print'
  gem 'stackprof'

  gem 'parallel_tests'

  gem 'letter_opener'
  gem 'letter_opener_web', '~> 1.4', '>= 1.4.1'

  gem 'dotenv-rails', '>= 2.7.6'
  gem 'bullet', '>= 7.1.6'
  gem 'byebug'
end

# I18n
gem 'rails-i18n', '>= 5.1.3'
gem 'devise-i18n', '>= 1.10.2'

gem 'activerecord-nulldb-adapter', require: (ENV['RAILS_DB_ADAPTER'] == 'nulldb')

gem 'google-cloud-storage', '>= 1.19.0'
gem 'net-sftp'
# Required by net-ssh to support various key types
gem 'ed25519'
gem 'x25519'
gem 'bcrypt_pbkdf'

gem 'bitset', en_route: 'bitset'
gem 'cuckoo', en_route: 'cuckoo'

gem 'curb'

gem 'chartkick'
gem 'groupdate'
