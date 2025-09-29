# frozen_string_literal: true

require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  SmartEnv.set :RAILS_DB_POOLSIZE, default: '5'
  SmartEnv.set :RAILS_DB_HOST, default: 'localhost'
  SmartEnv.set :RAILS_DB_NAME, default: 'chouette_test'
  SmartEnv.set :RAILS_DB_USER, default: nil
  SmartEnv.set :PUBLIC_HOST, default: 'http://www.example.com'
  SmartEnv.set :RAILS_HOST, default: 'http://localhost:3000'
  SmartEnv.set :IEV_URL, default: 'http://localhost:8080'

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = true

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_options = { from: 'Chouette <chouette@example.com>' }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = false

  config.secret_key_base = '7e4ef8715ea95895f2244b3715ed428f0565e2a822998955e85db139d64c19f9'

  config.action_mailer.default_url_options = { host: 'localhost:3000' }

  # Configure the e-mail address which will be shown in Devise::Maile
  config.mailer_sender = 'chouette@example.com'
  # change to true to allow email to be sent during development
  config.action_mailer.perform_deliveries = false
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default charset: 'utf-8'

  config.i18n.available_locales = %i[fr en]

  config.enable_transactional_checksums = true

  config.logger_reopen_max = 2
  config.logger_reopen_size = 250.megabytes
end

Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'), '*.rb')].each do |f|
  eval File.read(f), nil, f
end
