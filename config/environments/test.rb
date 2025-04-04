Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  SmartEnv.set :RAILS_DB_POOLSIZE, default: '5'
  SmartEnv.set :RAILS_DB_HOST, default: 'localhost'
  SmartEnv.set :RAILS_DB_NAME, default: 'chouette_test'
  SmartEnv.set :RAILS_DB_USER, default: nil
  SmartEnv.set :PUBLIC_HOST, default: 'http://www.example.com'
  SmartEnv.set :RAILS_HOST, default: 'http://localhost:3000'
  SmartEnv.set :IEV_URL, default: 'http://localhost:8080'

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_options = { from: 'Chouette <chouette@example.com>' }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.chouette_authentication_settings = {
    type: 'cas',
    cas_server: 'http://cas-portal.example.com/sessions'
  }

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

Dir[File.join(File.dirname(__FILE__), File.basename(__FILE__, ".rb"), "*.rb")].each do |f|
  eval File.read(f), nil, f
end
